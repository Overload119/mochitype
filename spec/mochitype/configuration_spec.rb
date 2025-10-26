# typed: false
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mochitype::Configuration do
  describe '#initialize' do
    it 'sets default watch_path' do
      config = described_class.new
      expect(config.watch_path).to eq('app/mochitypes/')
    end

    it 'sets default output_path' do
      config = described_class.new
      expect(config.output_path).to eq('app/javascript/__generated__/mochitypes')
    end
  end

  describe '#watch_path=' do
    it 'allows setting custom watch_path' do
      config = described_class.new
      config.watch_path = 'custom/path'
      expect(config.watch_path).to eq('custom/path')
    end
  end

  describe '#output_path=' do
    it 'allows setting custom output_path' do
      config = described_class.new
      config.output_path = 'custom/output'
      expect(config.output_path).to eq('custom/output')
    end
  end
end

RSpec.describe Mochitype do
  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(Mochitype.configuration).to be_a(Mochitype::Configuration)
    end

    it 'returns the same instance on multiple calls' do
      config1 = Mochitype.configuration
      config2 = Mochitype.configuration
      expect(config1).to be(config2)
    end
  end

  describe '.configure' do
    before do
      # Reset configuration
      Mochitype.instance_variable_set(:@configuration, nil)
    end

    it 'yields the configuration' do
      expect { |b| Mochitype.configure(&b) }.to yield_with_args(Mochitype::Configuration)
    end

    it 'allows configuring watch_path' do
      Mochitype.configure do |config|
        config.watch_path = 'test/path'
      end
      expect(Mochitype.configuration.watch_path).to eq('test/path')
    end

    it 'allows configuring output_path' do
      Mochitype.configure do |config|
        config.output_path = 'test/output'
      end
      expect(Mochitype.configuration.output_path).to eq('test/output')
    end

    it 'does not start the file watcher' do
      expect(Mochitype::FileWatcher).not_to receive(:start)
      Mochitype.configure { |config| }
    end
  end

  describe '.start_watcher!' do
    before do
      allow(Mochitype::FileWatcher).to receive(:start)
    end

    it 'starts the file watcher' do
      expect(Mochitype::FileWatcher).to receive(:start)
      Mochitype.start_watcher!
    end
  end
end
