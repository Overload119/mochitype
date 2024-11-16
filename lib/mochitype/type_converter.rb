require 'prism'

module Mochitype
  class TypeConverter
    class << self
      def convert_file(file_path)
        content = File.read(file_path)
        ast = parse_ruby(content)

        typescript_content = generate_typescript(ast)

        output_file = determine_output_path(file_path)
        FileUtils.mkdir_p(File.dirname(output_file))
        File.write(output_file, typescript_content)
      end

      private

      def parse_ruby(content)
        result = Prism.parse(content)

        # Find the first class that inherits from T::Struct
        struct_class = find_struct_class(result.value.statements)
        return nil unless struct_class

        struct_name = struct_class.constant_path.name.to_s
        props = extract_props(struct_class)

        { name: struct_name, props: props }
      end

      def find_struct_class(statements)
        statements.body.find do |stmt|
          next unless stmt.is_a?(Prism::ClassNode)

          parent = stmt.superclass
          next unless parent.is_a?(Prism::ConstantReadNode)

          # Check if it's T::Struct
          parent_path = parent.full_name
          parent_path == "T::Struct"
        end
      end

      def extract_props(class_node)
        props = {}

        class_node.body.statements.each do |stmt|
          next unless stmt.is_a?(Prism::CallNode) && stmt.name == :prop

          # Get property name from first argument
          name_node = stmt.arguments.arguments[0]
          next unless name_node.is_a?(Prism::SymbolNode)
          prop_name = name_node.value

          # Get type from second argument
          type_node = stmt.arguments.arguments[1]
          props[prop_name] = convert_type_from_node(type_node)
        end

        props
      end

      def convert_type_from_node(node)
        case node
        when Prism::ConstantReadNode
          case node.name
          when "String" then "z.string()"
          when "Integer" then "z.number()"
          when "Float" then "z.number()"
          else "z.unknown()"
          end
        when Prism::ConstantPathNode
          if node.parent&.name == "T"
            case node.child.name
            when "Boolean" then "z.boolean()"
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
              values = node.arguments&.arguments&.map do |arg|
                arg.is_a?(Prism::StringNode) ? arg.content : nil
              end.compact
              "z.enum([#{values.map(&:inspect).join(', ')}])"
            else
              "z.unknown()"
            end
          end
        when Prism::CallNode
          if node.name == :nilable && node.receiver&.name == "T"
            inner_type = convert_type_from_node(node.arguments.arguments.first)
            "#{inner_type}.nullable()"
          else
            "z.unknown()"
          end
        else
          "z.unknown()"
        end
      end

      def generate_typescript(ast)
        return '' unless ast

        imports = 'import { z } from "zod";\n\n'

        schema = "export const #{ast[:name]}Schema = z.object({\n"
        schema += ast[:props].map do |name, type|
          "  #{name}: #{type}"
        end.join(",\n")
        schema += "\n});\n\n"

        type = "export type #{ast[:name]} = z.infer<typeof #{ast[:name]}Schema>;\n"

        imports + schema + type
      end

      def determine_output_path(input_path)
        base_name = File.basename(input_path, '.*')
        output_dir = Rails.root.join(Mochitype.configuration.output_path)
        File.join(output_dir, "#{base_name}.ts")
      end
    end
  end
end
