# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mochitype::TypeConverter do
  describe '.determine_output_path' do
    before do
      Mochitype.instance_variable_set(:@configuration, nil)
      allow(Mochitype::FileWatcher).to receive(:start)
    end

    context 'with default configuration' do
      before do
        Mochitype.configure do |config|
          config.watch_path = 'app/mochitypes/'
          config.output_path = 'app/javascript/__generated__/mochitypes'
        end
      end

      it 'determines correct output path for a simple file' do
        input = '/rails_root/app/mochitypes/user.rb'
        output = described_class.determine_output_path(input)
        expect(output).to end_with('app/javascript/__generated__/mochitypes/user.ts')
      end

      it 'preserves directory structure' do
        input = '/rails_root/app/mochitypes/admin/users/profile.rb'
        output = described_class.determine_output_path(input)
        expect(output).to end_with('app/javascript/__generated__/mochitypes/admin/users/profile.ts')
      end

      it 'replaces .rb extension with .ts' do
        input = '/rails_root/app/mochitypes/test.rb'
        output = described_class.determine_output_path(input)
        expect(output).to end_with('.ts')
        expect(output).not_to end_with('.rb')
      end
    end

    context 'with custom configuration' do
      before do
        Mochitype.configure do |config|
          config.watch_path = 'custom/types'
          config.output_path = 'frontend/generated'
        end
      end

      it 'uses custom paths' do
        input = '/project/custom/types/models/user.rb'
        output = described_class.determine_output_path(input)
        expect(output).to end_with('frontend/generated/models/user.ts')
      end

      it 'handles nested directories in custom paths' do
        input = '/project/custom/types/api/v1/responses/user.rb'
        output = described_class.determine_output_path(input)
        expect(output).to end_with('frontend/generated/api/v1/responses/user.ts')
      end
    end

    context 'with Rails.root defined' do
      before do
        # Mock Rails.root
        rails_root = double('Rails.root')
        allow(rails_root).to receive(:join) { |path| "/rails_app/#{path}" }
        allow(Rails).to receive(:root).and_return(rails_root)

        Mochitype.configure do |config|
          config.watch_path = 'app/mochitypes'
          config.output_path = 'app/javascript/__generated__'
        end
      end

      it 'uses Rails.root to build absolute path' do
        input = '/rails_app/app/mochitypes/user.rb'
        output = described_class.determine_output_path(input)
        expect(output).to start_with('/rails_app/')
      end
    end
  end

  describe '.convert_file' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:test_file) { './spec/test-data/app.rb' }

    before do
      Mochitype.instance_variable_set(:@configuration, nil)
      allow(Mochitype::FileWatcher).to receive(:start)

      Mochitype.configure do |config|
        config.watch_path = 'spec/test-data'
        config.output_path = tmpdir
      end
    end

    after do
      FileUtils.rm_rf(tmpdir) if File.exist?(tmpdir)
    end

    it 'creates the output file' do
      output_path = described_class.convert_file(test_file)
      expect(File.exist?(output_path)).to be true
    end

    it 'creates necessary parent directories' do
      nested_file = File.join(tmpdir, 'source', 'nested', 'deep', 'test.rb')
      FileUtils.mkdir_p(File.dirname(nested_file))
      FileUtils.cp(test_file, nested_file)

      Mochitype.configure do |config|
        config.watch_path = File.join(tmpdir, 'source')
        config.output_path = File.join(tmpdir, 'output')
      end

      output_path = described_class.convert_file(nested_file)
      expect(File.exist?(output_path)).to be true
      expect(output_path).to include('output/nested/deep')
    end

    it 'returns the output file path' do
      output_path = described_class.convert_file(test_file)
      expect(output_path).to be_a(String)
      expect(output_path).to end_with('.ts')
    end

    it 'generates valid TypeScript content' do
      output_path = described_class.convert_file(test_file)
      content = File.read(output_path)

      expect(content).to include("import { z } from 'zod'")
      expect(content).to include('export const')
      expect(content).to include('export type')
    end
  end

  describe '.write_converted_file' do
    let(:tmpdir) { Dir.mktmpdir }
    let(:test_file) { './spec/test-data/app.rb' }
    let(:output_file) { File.join(tmpdir, 'output.ts') }

    before do
      allow(Mochitype::FileWatcher).to receive(:start)
    end

    after do
      FileUtils.rm_rf(tmpdir) if File.exist?(tmpdir)
    end

    it 'writes the converted TypeScript to the output file' do
      described_class.write_converted_file(
        in_filepath: test_file,
        out_filepath: output_file
      )
      expect(File.exist?(output_file)).to be true
    end

    it 'generates correct TypeScript syntax' do
      described_class.write_converted_file(
        in_filepath: test_file,
        out_filepath: output_file
      )

      content = File.read(output_file)
      expect(content).to match(/export const \w+ = z\.object/)
      expect(content).to match(/export type (T)?\w+ = z\.infer/)
    end
  end
end
