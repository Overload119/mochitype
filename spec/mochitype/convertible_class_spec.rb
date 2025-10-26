# frozen_string_literal: true

require 'spec_helper'

# Define test structs and enums
class TestStruct < T::Struct
  const :name, String
end

class TestEnum < T::Enum
  enums do
    RED = new
    BLUE = new
  end
end

module NamespaceTest
  class NestedStruct < T::Struct
    const :id, Integer
  end
end

RSpec.describe ConvertibleClass do
  describe '#typescript_name' do
    context 'with T::Struct classes' do
      it 'appends Schema to the class name' do
        convertible = described_class.new(klass: TestStruct)
        expect(convertible.typescript_name).to eq('TestStructSchema')
      end

      it 'removes namespace separators' do
        convertible = described_class.new(klass: NamespaceTest::NestedStruct)
        expect(convertible.typescript_name).to eq('NamespaceTestNestedStructSchema')
      end
    end

    context 'with T::Enum classes' do
      it 'appends Enum to the class name' do
        convertible = described_class.new(klass: TestEnum)
        expect(convertible.typescript_name).to eq('TestEnumEnum')
      end
    end

    context 'with deeply nested classes' do
      it 'flattens all namespace separators' do
        # Using the existing test data
        Dir.glob('./spec/test-data/*.rb').each { |filepath| 
          require_relative filepath.sub('./spec/', '../') 
        }
        
        convertible = described_class.new(klass: Payload::Result)
        expect(convertible.typescript_name).to eq('PayloadResultSchema')
      end
    end
  end

  describe 'initialization' do
    it 'requires a klass parameter' do
      convertible = described_class.new(klass: TestStruct)
      expect(convertible.klass).to eq(TestStruct)
    end

    it 'initializes with empty props by default' do
      convertible = described_class.new(klass: TestStruct)
      expect(convertible.props).to eq({})
    end

    it 'initializes with empty inner_classes by default' do
      convertible = described_class.new(klass: TestStruct)
      expect(convertible.inner_classes).to eq([])
    end
  end

  describe 'props management' do
    it 'allows setting props' do
      convertible = described_class.new(klass: TestStruct)
      convertible.props = { 'name' => 'z.string()' }
      expect(convertible.props).to eq({ 'name' => 'z.string()' })
    end

    it 'stores multiple properties' do
      convertible = described_class.new(klass: TestStruct)
      convertible.props = {
        'id' => 'z.number()',
        'name' => 'z.string()',
        'active' => 'z.boolean()'
      }
      expect(convertible.props.keys).to contain_exactly('id', 'name', 'active')
    end
  end

  describe 'inner_classes management' do
    it 'allows setting inner_classes' do
      parent = described_class.new(klass: TestStruct)
      child = described_class.new(klass: TestEnum)
      parent.inner_classes = [child]
      expect(parent.inner_classes).to eq([child])
    end

    it 'handles multiple inner classes' do
      parent = described_class.new(klass: TestStruct)
      child1 = described_class.new(klass: TestEnum)
      child2 = described_class.new(klass: NamespaceTest::NestedStruct)
      
      parent.inner_classes = [child1, child2]
      expect(parent.inner_classes.length).to eq(2)
    end
  end
end
