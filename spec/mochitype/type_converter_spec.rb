require 'spec_helper'
require 'pry'

# Require all Ruby files in the test data directory
Dir
  .glob('./spec/test-data/*.rb')
  .each { |filepath| require_relative filepath.sub('./spec/', '../') }

RSpec.describe Mochitype::TypeConverter do
  before { Rails.logger = Logger.new($stdout) }

  describe '.convert_file' do
    Dir['./spec/test-data/*.rb'].each do |filepath|
      filename = File.basename(filepath)

      it "converts #{filename} to a Zod TypeScript file" do
        tmpdir = Dir.mktmpdir
        Mochitype.configure do |config|
          config.watch_path = Dir.mktmpdir
          config.output_path = tmpdir
        end

        expect(File.read(described_class.convert_file(filepath))).to eq(
          File.read(
            File.expand_path("./spec/test-data/__generated__/#{filename.sub('.rb', '.ts')}"),
          ),
        )
      end
    end
  end
end
