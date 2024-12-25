# typed: true
# frozen_string_literal: true

module Mochitype
  class TypeConverter
    extend T::Sig

    class << self
      extend T::Sig

      class TypeData < T::Struct
        const :name, String
        const :props, T::Hash[String, String]
      end

      sig { params(file_path: String).returns(T.nilable(String)) }
      def convert_file(file_path)
        content = File.read(file_path)
        ast = parse_ruby(content)

        return if ast.nil?

        typescript_content = generate_typescript(ast)

        output_file = determine_output_path(file_path)
        FileUtils.mkdir_p(File.dirname(output_file))
        File.write(output_file, typescript_content)

        output_file
      end

      private

      sig { params(content: String).returns(T.nilable(TypeData)) }
      def parse_ruby(content)
        result = Prism.parse(content)

        # Find the first class that inherits from T::Struct
        struct_class = find_struct_class(result.value.statements)
        return nil unless struct_class

        struct_name = T.unsafe(struct_class).constant_path.name.to_s
        props = extract_props(struct_class)

        TypeData.new(name: struct_name, props: props)
      end

      sig { params(statements: Prism::StatementsNode).returns(T.nilable(Prism::Node)) }
      def find_struct_class(statements)
        statements.body.find do |stmt|
          next unless stmt.is_a?(Prism::ClassNode)

          parent = stmt.superclass
          next unless parent.is_a?(Prism::ConstantPathNode)

          parent_path = parent.full_name
          parent_path == "T::Struct"
        end
      end

      sig { params(class_node: Prism::ClassNode).returns(T::Hash[String, String]) }
      def extract_props(class_node)
        props = {}

        T
          .cast(class_node.body, Prism::StatementsNode)
          .body
          .each do |stmt|
            next unless stmt.is_a?(Prism::CallNode) && %i[prop const].include?(stmt.name)

            stmt = T.unsafe(stmt)

            name_node = stmt.arguments.arguments[0]
            next unless name_node.is_a?(Prism::SymbolNode)
            prop_name = name_node.value.to_s

            # Get type from second argument
            type_node = stmt.arguments.arguments[1]
            props[prop_name] = convert_type_from_node(type_node)
          end

        props
      end

      sig { params(node: T.untyped).returns(String) }
      def convert_type_from_node(node)
        # binding.pry
        case node
        when Prism::ConstantReadNode
          case node.name.to_s
          when "String"
            "z.string()"
          when "Integer"
            "z.number()"
          when "Float"
            "z.number()"
          else
            "z.unknown()"
          end
        when Prism::ConstantPathNode
          if node.parent&.name.to_s == "T"
            case node.child.name.to_s
            when "Boolean"
              "z.boolean()"
            when "Array"
              if node.arguments&.arguments&.first
                inner_type = convert_type_from_node(node.arguments.arguments.first)
                "z.array(#{inner_type})"
              else
                "z.array(z.unknown())"
              end
            when "Hash"
              args = node.arguments&.arguments
              if args&.size == 2
                key_type = convert_type_from_node(args[0])
                value_type = convert_type_from_node(args[1])
                "z.record(#{key_type}, #{value_type})"
              else
                "z.record(z.unknown(), z.unknown())"
              end
            when "Enum"
              values =
                node
                  .arguments
                  &.arguments
                  &.map { |arg| arg.is_a?(Prism::StringNode) ? arg.content : nil }
                  .compact
              "z.enum([#{values.map(&:inspect).join(", ")}])"
            else
              "z.unknown()"
            end
          end
        when Prism::CallNode
          convert_type_from_call_node(node)
        else
          "z.unknown()"
        end
      end

      sig { params(node: Prism::CallNode).returns(String) }
      def convert_type_from_call_node(node)
        receiver = node.receiver
        if node.name == :nilable && receiver.is_a?(Prism::ConstantReadNode) && receiver.name == :T
          inner_type = convert_type_from_node(node.arguments&.arguments&.first)
          "#{inner_type}.nullable()"
        elsif node.name == :[]
          # Handles T::Array[x, y] or T::Hash[x]
          if receiver.is_a?(Prism::ConstantPathNode) && receiver.full_name == "T::Array"
            inner_type = convert_type_from_node(node.arguments&.arguments&.first)
            "z.array(#{inner_type})"
          elsif receiver.is_a?(Prism::ConstantPathNode) && receiver.full_name == "T::Hash"
            key_type = convert_type_from_node(node.arguments&.arguments&.first)
            value_type = convert_type_from_node(node.arguments&.arguments&.last)
            "z.record(#{key_type}, #{value_type})"
          else
            "z.unknown()"
          end
        else
          "z.unknown()"
        end
      end

      sig { params(ast: TypeData).returns(String) }
      def generate_typescript(ast)
        imports = String.new("/**\n")
        imports << "/* This file is generated by Mochitype. Do not edit it by hand.\n"
        imports << "/**/\n\n"
        imports << "import { z } from 'zod';\n\n"

        schema = "export const #{ast.name}Schema = z.object({\n"
        schema += ast.props.map { |name, type| "  #{name}: #{type}" }.join(",\n")
        schema += "\n});\n\n"

        type = "export type #{ast.name} = z.infer<typeof #{ast.name}Schema>;\n"

        imports + schema + type
      end

      sig { params(input_path: String).returns(String) }
      def determine_output_path(input_path)
        base_name = File.basename(input_path, ".*")
        output_dir = Mochitype.configuration.output_path
        File.join(output_dir, "#{base_name}.ts")
      end
    end
  end
end
