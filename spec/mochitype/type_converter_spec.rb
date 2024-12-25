require "spec_helper"
require "pry"

RSpec.describe Mochitype::TypeConverter do
  describe ".convert_file" do
    Dir["./spec/test-data/*.rb"].each do |filepath|
      filename = File.basename(filepath)

      it "converts #{filename} to a Zod TypeScript file" do
        tmpdir = Dir.mktmpdir
        Mochitype.configure { |config| config.output_path = tmpdir }

        expect(File.read(described_class.convert_file(filepath))).to eq(
          File.read(
            File.expand_path("./spec/test-data/__generated__/#{filename.sub(".rb", ".ts")}")
          )
        )
      end
    end
  end
end
