require 'spec_helper'

RSpec.describe Mochitype::TypeConverter do
  describe '.convert_file' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:input_file) { File.join(temp_dir, 'user.rb') }
    let(:output_file) { File.join(temp_dir, 'types', 'user.ts') }

    before do
      allow(Rails).to receive_message_chain(:root, :join) { Pathname.new(temp_dir) }
      allow(Mochitype.configuration).to receive(:output_path) { 'types' }
    end

    after do
      FileUtils.remove_entry temp_dir
    end

    it 'converts a Sorbet struct to a Zod TypeScript file' do
      File.write(input_file, <<~RUBY)
        class User < T::Struct
          prop :name, String
          prop :age, Integer
          prop :is_admin, T::Boolean
          prop :tags, T::Array[String]
          prop :metadata, T::Hash[String, String]
          prop :role, T.nilable(String)
          prop :status, T::Enum['active', 'inactive']
        end
      RUBY

      described_class.convert_file(input_file)

      expected_content = <<~TYPESCRIPT
        import { z } from "zod";

        export const UserSchema = z.object({
          name: z.string(),
          age: z.number(),
          is_admin: z.boolean(),
          tags: z.array(z.string()),
          metadata: z.record(z.string(), z.string()),
          role: z.string().nullable(),
          status: z.enum(["active", "inactive"])
        });

        export type User = z.infer<typeof UserSchema>;
      TYPESCRIPT

      expect(File.exist?(output_file)).to be true
      expect(File.read(output_file)).to eq(expected_content)
    end
  end
end
