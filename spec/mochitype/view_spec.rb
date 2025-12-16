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
        instance = test_class.new(tags: %w[ruby rails], scores: [1, 2, 3])
        result = instance.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed['tags']).to eq(%w[ruby rails])
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

      it 'explicitly includes nil keys in the JSON output' do
        instance = test_class.new(name: 'Charlie', nickname: nil)
        result = instance.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed).to have_key('nickname')
        expect(parsed.keys).to contain_exactly('name', 'nickname')
      end
    end

    context 'with nilable nested T::Struct' do
      let(:address_class) do
        Class.new(T::Struct) do
          const :street, String
          const :city, String
          const :zip, T.nilable(String)
        end
      end

      let(:user_class) do
        address_class_ref = address_class
        Class.new(T::Struct) do
          include Mochitype::View

          const :name, String
          const :address, T.nilable(address_class_ref)
        end
      end

      it 'includes nil key when nested struct is nil' do
        user = user_class.new(name: 'Dave', address: nil)
        result = user.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed).to have_key('address')
        expect(parsed['address']).to be_nil
        expect(parsed.keys).to contain_exactly('name', 'address')
      end

      it 'recursively serializes nested struct with nil fields' do
        address = address_class.new(street: '456 Oak Ave', city: 'Portland', zip: nil)
        user = user_class.new(name: 'Eve', address: address)
        result = user.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed['name']).to eq('Eve')
        expect(parsed['address']).to have_key('zip')
        expect(parsed['address']['zip']).to be_nil
        expect(parsed['address'].keys).to contain_exactly('street', 'city', 'zip')
      end
    end

    context 'with arrays of structs containing nil values' do
      let(:item_class) do
        Class.new(T::Struct) do
          const :id, Integer
          const :label, T.nilable(String)
        end
      end

      let(:container_class) do
        item_class_ref = item_class
        Class.new(T::Struct) do
          include Mochitype::View

          const :items, T::Array[item_class_ref]
        end
      end

      it 'serializes arrays of structs with nil fields correctly' do
        items = [
          item_class.new(id: 1, label: 'First'),
          item_class.new(id: 2, label: nil),
          item_class.new(id: 3, label: 'Third'),
        ]
        container = container_class.new(items: items)
        result = container.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed['items'].length).to eq(3)
        expect(parsed['items'][0]).to eq({ 'id' => 1, 'label' => 'First' })
        expect(parsed['items'][1]).to have_key('label')
        expect(parsed['items'][1]['label']).to be_nil
        expect(parsed['items'][2]).to eq({ 'id' => 3, 'label' => 'Third' })
      end
    end

    context 'with deeply nested structs and nil values' do
      let(:inner_class) { Class.new(T::Struct) { const :value, T.nilable(String) } }

      let(:middle_class) do
        inner_class_ref = inner_class
        Class.new(T::Struct) do
          const :inner, T.nilable(inner_class_ref)
          const :name, String
        end
      end

      let(:outer_class) do
        middle_class_ref = middle_class
        Class.new(T::Struct) do
          include Mochitype::View

          const :middle, T.nilable(middle_class_ref)
          const :id, Integer
        end
      end

      it 'handles deeply nested nil structs' do
        outer = outer_class.new(middle: nil, id: 1)
        result = outer.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed).to have_key('middle')
        expect(parsed['middle']).to be_nil
      end

      it 'handles deeply nested structs with nil values at various levels' do
        inner = inner_class.new(value: nil)
        middle = middle_class.new(inner: inner, name: 'test')
        outer = outer_class.new(middle: middle, id: 1)
        result = outer.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed['middle']['inner']).to have_key('value')
        expect(parsed['middle']['inner']['value']).to be_nil
      end
    end

    context 'with nested struct containing nilable enum' do
      # T::Enum requires constants, so we define it as a proper named class
      class TestStatusEnum < T::Enum
        enums do
          ACTIVE = new
          INACTIVE = new
        end
      end

      class TestProfileStruct < T::Struct
        const :name, String
        const :status, T.nilable(TestStatusEnum)
      end

      let(:user_class) do
        Class.new(T::Struct) do
          include Mochitype::View

          const :profile, TestProfileStruct
        end
      end

      it 'serializes nested struct with nil enum' do
        profile = TestProfileStruct.new(name: 'Test', status: nil)
        user = user_class.new(profile: profile)
        result = user.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed['profile']).to have_key('status')
        expect(parsed['profile']['status']).to be_nil
        expect(parsed['profile'].keys).to contain_exactly('name', 'status')
      end

      it 'serializes nested struct with enum value' do
        profile = TestProfileStruct.new(name: 'Test', status: TestStatusEnum::ACTIVE)
        user = user_class.new(profile: profile)
        result = user.render_in(view_context)

        parsed = JSON.parse(result)
        expect(parsed['profile']['status']).to eq('active')
      end
    end
  end

  describe '#serialize' do
    context 'overrides T::Struct default serialize' do
      let(:test_class) do
        Class.new(T::Struct) do
          include Mochitype::View

          const :name, String
          const :nickname, T.nilable(String)
        end
      end

      it 'returns a hash' do
        instance = test_class.new(name: 'Test', nickname: nil)
        result = instance.serialize

        expect(result).to be_a(Hash)
      end

      it 'includes nil keys unlike default T::Struct serialize' do
        instance = test_class.new(name: 'Test', nickname: nil)
        result = instance.serialize

        expect(result).to have_key('nickname')
        expect(result['nickname']).to be_nil
        expect(result.keys).to contain_exactly('name', 'nickname')
      end

      it 'serializes non-nil values correctly' do
        instance = test_class.new(name: 'Test', nickname: 'Testy')
        result = instance.serialize

        expect(result).to eq({ 'name' => 'Test', 'nickname' => 'Testy' })
      end
    end

    context 'with nested structs' do
      let(:child_class) do
        Class.new(T::Struct) do
          const :value, String
          const :optional, T.nilable(Integer)
        end
      end

      let(:parent_class) do
        child_ref = child_class
        Class.new(T::Struct) do
          include Mochitype::View

          const :child, T.nilable(child_ref)
          const :name, String
        end
      end

      it 'recursively serializes nested structs with nil keys' do
        child = child_class.new(value: 'test', optional: nil)
        parent = parent_class.new(child: child, name: 'Parent')
        result = parent.serialize

        expect(result['child']).to have_key('optional')
        expect(result['child']['optional']).to be_nil
      end

      it 'includes nil key for nil nested struct' do
        parent = parent_class.new(child: nil, name: 'Parent')
        result = parent.serialize

        expect(result).to have_key('child')
        expect(result['child']).to be_nil
      end
    end

    context 'with enums' do
      let(:parent_with_enum) do
        Class.new(T::Struct) do
          include Mochitype::View

          const :status, T.nilable(TestStatusEnum)
          const :name, String
        end
      end

      it 'serializes enum to string value' do
        instance = parent_with_enum.new(status: TestStatusEnum::ACTIVE, name: 'Test')
        result = instance.serialize

        expect(result['status']).to eq('active')
      end

      it 'includes nil key for nil enum' do
        instance = parent_with_enum.new(status: nil, name: 'Test')
        result = instance.serialize

        expect(result).to have_key('status')
        expect(result['status']).to be_nil
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
      expect(parsed).to eq({ 'id' => 1, 'email' => 'test@example.com', 'active' => true })
    end
  end
end
