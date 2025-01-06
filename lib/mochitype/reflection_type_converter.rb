# typed: true
# frozen_string_literal: true

module Mochitype
  class ReflectionTypeConverter
    extend T::Sig

    SORBET_TYPESCRIPT_MAPPING = {
      String => 'z.string()',
      Integer => 'z.number()',
      Float => 'z.number()',
      Numeric => 'z.number()',
    }

    sig { params(file_path: String).void }
    def initialize(file_path)
      @file_path = file_path
    end

    # Entrypoint to generate the Typescript file content from the main struct that's being converted.
    sig { returns(String) }
    def build_typescript_file
      buffer = String.new("/**\n")
      buffer << "/* This file is generated by Mochitype. Do not edit it by hand.\n"
      buffer << "/**/\n\n"
      buffer << "import { z } from 'zod';\n\n"

      buffer << convertible_class_to_typescript(root_convertible_class)
      buffer.strip!
      buffer << "\n"
    end

    sig { params(convertible_class: ConvertibleClass).returns(String) }
    def convertible_class_to_typescript(convertible_class)
      buffer = String.new

      if convertible_class.klass < T::Enum
        values = T.unsafe(convertible_class.klass).values.map(&:serialize).map { "'#{_1}'" }
        buffer << "export const #{convertible_class.typescript_name} = z.enum([#{values.join(', ')}]);\n\n"
      elsif convertible_class.klass < T::Struct
        # Populate the properties.
        properties = {}
        inner_classes = T.let([], T::Array[ConvertibleClass])
        T
          .cast(convertible_class.klass, T.class_of(T::Struct))
          .props
          .each do |property_name, data|
            convertible_property = write_prop(data)
            properties[property_name.to_s] = convertible_property.zod_definition
            inner_classes +=
              convertible_property.discovered_classes.map do |klass|
                ConvertibleClass.new(klass: klass)
              end
          end

        convertible_class.props = properties
        convertible_class.inner_classes = inner_classes

        # Before adding this convertible class into the TypeScript file, we have to make sure all of
        # its dependencies are added first.
        convertible_class.inner_classes.each do |inner_class|
          buffer << convertible_class_to_typescript(inner_class)
        end

        buffer << "export const #{convertible_class.typescript_name} = z.object({\n"
        buffer << convertible_class.props.map { |name, type| "  #{name}: #{type}" }.join(",\n")
        buffer << "\n});\n\n"
      else
        raise NotImplementedError, "Unknown type: #{convertible_class.klass}"
      end

      buffer << "export type T#{convertible_class.typescript_name} = z.infer<typeof #{convertible_class.typescript_name}>;\n\n"
      buffer
    end

    sig { returns(ConvertibleClass) }
    def root_convertible_class
      klass = T.cast(extract_main_klass.constantize, T.class_of(T::Struct))

      ConvertibleClass.new(klass: klass)
    end

    # Computes the Typescript-property of a T::Struct.
    sig { params(data: T::Hash[Symbol, T.untyped]).returns(ConvertibleProperty) }
    def write_prop(data)
      case data[:type].class.to_s
      when 'T::Types::TypedArray'
        inner_type = data[:type].type.raw_type
        value = simple_class_to_typescript(inner_type)
        ConvertibleProperty.new(
          zod_definition: "z.array(#{value.zod_definition})",
          discovered_classes: value.discovered_classes,
        )
      when 'T::Private::Types::SimplePairUnion'
        first_value = data[:type].types[0].raw_type
        second_value = data[:type].types[1].raw_type
        if [first_value, second_value].to_set == [TrueClass, FalseClass].to_set
          ConvertibleProperty.new(zod_definition: 'z.boolean()', discovered_classes: [])
        else
          fv = simple_class_to_typescript(first_value)
          sv = simple_class_to_typescript(second_value)

          ConvertibleProperty.new(
            zod_definition: "z.union([#{fv.zod_definition}, #{sv.zod_definition}])",
            discovered_classes: (fv.discovered_classes + sv.discovered_classes).uniq,
          )
        end
      when 'T::Types::TypedHash'
        ConvertibleProperty.new(
          zod_definition: "z.record(#{data[:type].first}, #{data[:type].last})",
          discovered_classes: [],
        )
      when 'T::Types::Union'
        union_types = data[:type].types.map(&:raw_type)
        properties = union_types.map { |union_type| simple_class_to_typescript(union_type) }

        values = properties.map(&:zod_definition)
        discovered_classes = properties.flat_map(&:discovered_classes).uniq

        ConvertibleProperty.new(
          zod_definition: "z.union([#{values.join(',')}])",
          discovered_classes: discovered_classes,
        )
      else
        if data[:_tnilable]
          value = simple_class_to_typescript(data[:type])
          ConvertibleProperty.new(zod_definition: "#{value.zod_definition}.nullable()")
        else
          simple_class_to_typescript(data[:type])
        end
      end
    end

    sig { params(klass: T.untyped).returns(ConvertibleProperty) }
    def simple_class_to_typescript(klass)
      case
      when klass < T::Struct
        inner_klass = ConvertibleClass.new(klass: klass)
        ConvertibleProperty.new(
          zod_definition: inner_klass.typescript_name,
          discovered_classes: [klass],
        )
      when klass < T::Enum
        inner_klass = ConvertibleClass.new(klass: klass)
        ConvertibleProperty.new(
          zod_definition: inner_klass.typescript_name,
          discovered_classes: [klass],
        )
      when SORBET_TYPESCRIPT_MAPPING.key?(klass)
        ConvertibleProperty.new(zod_definition: SORBET_TYPESCRIPT_MAPPING[klass])
      else
        ConvertibleProperty.new(zod_definition: 'z.unknown()')
      end
    end

    # Reads the primary class that is being converted.
    # @return a namespaced class name
    sig { returns(String) }
    def extract_main_klass
      ast = Prism.parse(File.read(@file_path))

      class_name = T.let(nil, T.nilable(String))
      nodes_to_visit = ast.value.statements.body.dup
      module_names = []

      # Traverse until we find the first class that's a T::Struct
      while node = nodes_to_visit.shift
        if node.is_a?(Prism::ModuleNode)
          module_names << node.name.to_s
        elsif node.is_a?(Prism::ClassNode)
          parent = node.superclass

          if parent.is_a?(Prism::ConstantPathNode) &&
               (parent.full_name == 'T::Struct' || parent.full_name == 'T::Enum')
            class_name = node.name.to_s
            break
          end
        end

        nodes_to_visit.concat(node.child_nodes.compact)
      end

      [*module_names, T.must(class_name)].compact.join('::')
    end
  end
end
