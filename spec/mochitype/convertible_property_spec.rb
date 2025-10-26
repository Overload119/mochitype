# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mochitype::ConvertibleProperty do
  describe 'initialization' do
    it 'requires a zod_definition' do
      prop = described_class.new(zod_definition: 'z.string()')
      expect(prop.zod_definition).to eq('z.string()')
    end

    it 'initializes with empty discovered_classes by default' do
      prop = described_class.new(zod_definition: 'z.string()')
      expect(prop.discovered_classes).to eq([])
    end

    it 'accepts discovered_classes parameter' do
      prop = described_class.new(
        zod_definition: 'CustomTypeSchema',
        discovered_classes: [String, Integer]
      )
      expect(prop.discovered_classes).to eq([String, Integer])
    end
  end

  describe 'immutability' do
    it 'uses const for zod_definition' do
      prop = described_class.new(zod_definition: 'z.string()')
      expect { prop.zod_definition = 'z.number()' }.to raise_error(NoMethodError)
    end

    it 'uses const for discovered_classes' do
      prop = described_class.new(zod_definition: 'z.string()', discovered_classes: [])
      expect { prop.discovered_classes = [String] }.to raise_error(NoMethodError)
    end
  end

  describe 'with different zod types' do
    it 'handles primitive types' do
      primitives = {
        'z.string()' => String,
        'z.number()' => Integer,
        'z.boolean()' => TrueClass
      }

      primitives.each do |zod, _klass|
        prop = described_class.new(zod_definition: zod)
        expect(prop.zod_definition).to eq(zod)
      end
    end

    it 'handles complex types' do
      prop = described_class.new(zod_definition: 'z.array(z.string())')
      expect(prop.zod_definition).to eq('z.array(z.string())')
    end

    it 'handles union types' do
      prop = described_class.new(zod_definition: 'z.union([z.string(), z.number()])')
      expect(prop.zod_definition).to eq('z.union([z.string(), z.number()])')
    end

    it 'handles nullable types' do
      prop = described_class.new(zod_definition: 'z.string().nullable()')
      expect(prop.zod_definition).to eq('z.string().nullable()')
    end

    it 'handles record types' do
      prop = described_class.new(zod_definition: 'z.record(z.string(), z.unknown())')
      expect(prop.zod_definition).to eq('z.record(z.string(), z.unknown())')
    end

    it 'handles custom schema references' do
      class CustomClass < T::Struct; end
      prop = described_class.new(
        zod_definition: 'CustomClassSchema',
        discovered_classes: [CustomClass]
      )
      expect(prop.zod_definition).to eq('CustomClassSchema')
      expect(prop.discovered_classes).to include(CustomClass)
    end
  end
end
