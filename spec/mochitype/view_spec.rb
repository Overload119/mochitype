# frozen_string_literal: true
# typed: false

require 'spec_helper'
require 'action_view'

RSpec.describe Mochitype::View do
  let(:view_context) { ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil) }

  describe '#render_in' do
    context 'with a simple T::Struct' do
      let(:test_class) do
        Class.new(T::Struct) do
          include Mochitype::View

          const :name, String
          const :age, Integer
        end
      end

      it 'serializes the struct to JSON' do
        instance = test_class.new(name: 'Alice', age: 30)
        result = instance.render_in(view_context)
        
        expect(result).to be_a(String)
        parsed = JSON.parse(result)
        expect(parsed['name']).to eq('Alice')
        expect(parsed['age']).to eq(30)
      end
    end

    context 'with nested T::Structs' do
      let(:address_class) do
        Class.new(T::Struct) do
          const :street, String
          const :city, String
        end
      end

      let(:user_class) do
        address_class_ref = address_class
        Class.new(T::Struct) do
          include Mochitype::View

          const :name, String
          const :address, address_class_ref
        end
      end

      it 'serializes nested structs correctly' do
        address = address_class.new(street: '123 Main St', city: 'Springfield')
        user = user_class.new(name: 'Bob', address: address)
        
        result = user.render_in(view_context)
        parsed = JSON.parse(result)
        
        expect(parsed['name']).to eq('Bob')
        expect(parsed['address']['street']).to eq('123 Main St')
        expect(parsed['address']['city']).to eq('Springfield')
      end
    end

    context 'with arrays' do
      let(:test_class) do
        Class.new(T::Struct) do
          include Mochitype::View

          const :tags, T::Array[String]
          const :scores, T::Array[Integer]
        end
      end

      it 'serializes arrays correctly' do
        instance = test_class.new(tags: ['ruby', 'rails'], scores: [1, 2, 3])
        result = instance.render_in(view_context)
        
        parsed = JSON.parse(result)
        expect(parsed['tags']).to eq(['ruby', 'rails'])
        expect(parsed['scores']).to eq([1, 2, 3])
      end
    end

    context 'with nilable fields' do
      let(:test_class) do
        Class.new(T::Struct) do
          include Mochitype::View

          const :name, String
          const :nickname, T.nilable(String)
        end
      end

      it 'handles nil values correctly' do
        instance = test_class.new(name: 'Charlie', nickname: nil)
        result = instance.render_in(view_context)
        
        parsed = JSON.parse(result)
        expect(parsed['name']).to eq('Charlie')
        expect(parsed['nickname']).to be_nil
      end
    end
  end

  describe '#format' do
    let(:test_class) do
      Class.new(T::Struct) do
        include Mochitype::View

        const :name, String
      end
    end

    it 'returns :json format' do
      instance = test_class.new(name: 'Test')
      expect(instance.format).to eq(:json)
    end
  end

  describe 'integration with Rails controllers' do
    let(:user_struct) do
      Class.new(T::Struct) do
        include Mochitype::View

        const :id, Integer
        const :email, String
        const :active, T::Boolean

        def self.name
          'UserResponse'
        end
      end
    end

    it 'can be rendered directly in controller context' do
      user = user_struct.new(id: 1, email: 'test@example.com', active: true)
      
      # Simulate what happens in a controller
      result = user.render_in(view_context)
      expect(result).to be_a(String)
      
      parsed = JSON.parse(result)
      expect(parsed).to eq({
        'id' => 1,
        'email' => 'test@example.com',
        'active' => true
      })
    end
  end
end
