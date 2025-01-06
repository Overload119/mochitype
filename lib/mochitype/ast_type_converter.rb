# typed: true
# frozen_string_literal: true

module Mochitype
  class AstTypeConverter
    extend T::Sig

    class << self
      extend T::Sig

      # Represents data that will be turned into a Typescript Zod type.
      class TypeData < T::Struct
        extend T::Sig

        const :name, String
        prop :props, T::Hash[String, String], default: {}
        const :base_class_name, String

        # The name of the type in the generated Typescript file.
        sig { returns(String) }
        def typescript_name
          base_class_name.include?('T::Enum') ? "#{name}Enum" : "#{name}Schema"
        end
      end

      sig { params(file_path: String).returns(T.nilable(String)) }
      def convert_file(file_path)
        @file_path = file_path
        @module_names = T.let([], T.nilable(T::Array[String]))

        type_data = parse_ruby(file_path)

        return if type_data.empty?

        typescript_content = generate_typescript(type_data)

        output_file = determine_output_path(file_path)
        FileUtils.mkdir_p(File.dirname(output_file))
        File.write(output_file, typescript_content)

        output_file
      end

      private

      sig { params(file_path: String).returns(T::Array[TypeData]) }
      def parse_ruby(file_path)
        result = Prism.parse(File.read(file_path))
        @classes = find_classes(result.value.statements)
        @class_names = @classes.map { |class_node| T.unsafe(class_node).constant_path.name.to_s }

        return [] if @classes.empty?

        @type_datas =
          @classes.map do |class_node|
            class_name = T.unsafe(class_node).constant_path.name.to_s
            parent = T.cast(class_node.superclass, Prism::ConstantPathNode)
            TypeData.new(name: class_name, base_class_name: parent.full_name)
          end

        @type_datas.each.with_index do |td, index|
          td.props = extract_props(T.cast(@classes[index], Prism::ClassNode))
        end

        @type_datas
      end

      # Finds all the class nodes that will turn into Typescript Zod types.
      #
      # We only care about classes that extend T::Struct or T::Enum since those are serializable.
      # Other classes are not supported.
      sig { params(statements: Prism::StatementsNode).returns(T::Array[Prism::ClassNode]) }
      def find_classes(statements)
        classes = []
        nodes_to_visit = statements.body.dup

        while node = nodes_to_visit.shift
          if node.is_a?(Prism::ClassNode)
            parent = node.superclass

            if parent.is_a?(Prism::ConstantPathNode) &&
                 (parent.full_name == 'T::Struct' || parent.full_name == 'T::Enum')
              classes << node
            end
          end

          nodes_to_visit.concat(node.child_nodes.compact)
        end

        classes
      end

      # Extracts the properties of a Prism class node.
      # A class node is either a T::Struct or T::Enum.
      # In the case of T::Struct, we look at each `const` or `prop` and map it to the Typescript value.
      #
      #
      # @example { my_variable: string }
      # @example { my_variable: MyCustomType }
      # @example { my_variable: number }
      sig { params(class_node: Prism::ClassNode).returns(T::Hash[String, String]) }
      def extract_props(class_node)
        props = {}

        supported_property_names = %i[prop const]

        T
          .cast(class_node.body, Prism::StatementsNode)
          .body
          .each do |stmt|
            next unless stmt.is_a?(Prism::CallNode) && supported_property_names.include?(stmt.name)

            stmt = T.unsafe(stmt)

            name_node = stmt.arguments.arguments[0]
            next unless name_node.is_a?(Prism::SymbolNode)
            prop_name = name_node.value.to_s

            # Get type from second argument
            type_node = stmt.arguments.arguments[1]
            props[prop_name] = convert_type_from_node(type_node, statement_node: stmt)
          end

        props
      end

      sig { params(class_node: Prism::ClassNode).returns(T::Array[String]) }
      def extract_enum_values(class_node)
        enums_block =
          T
            .cast(class_node.body, Prism::StatementsNode)
            .body
            .find { |stmt| stmt.is_a?(Prism::CallNode) && stmt.name == :enums }

        return [] unless enums_block
        return [] unless T.unsafe(enums_block).block

        T
          .cast(T.unsafe(enums_block).block.body, Prism::StatementsNode)
          .body
          .filter_map do |stmt|
            next unless stmt.is_a?(Prism::CallNode)
            T.unsafe(stmt).name.to_s.upcase
          end
      end

      # Handles simple ClassNodes
      # If something is unhandled here, it must be a class that extends T::Struct or T::Enum.
      sig { params(node: Prism::ConstantReadNode, statement_node: Prism::Node).returns(String) }
      def typescript_type_from_constant_read_node(node, statement_node)
        name = T.unsafe(node).name.to_s
        case name
        when 'String'
          'z.string()'
        when 'Integer', 'Numeric', 'Float'
          'z.number()'
        else
          # This is referring to another type that we will export in the final TS type.
          # We refer to its TS name.
          matching_type_data = @type_datas.find { |td| td.name == name }
          if matching_type_data
            matching_type_data.typescript_name
          else
            # Use reflection.
            klass = "#{[*@module_names, name].join('::')}".constantize

            raise NotImplementedError, "Unknown type: #{name}"
          end
        end
      end

      # Outputs a string intended to be added to the Typescript file, representing the type of the node.
      #
      # @param node - The node to convert to a Typescript type.
      # @param statement_node - The entire statement node - may not be needed.
      sig { params(node: Prism::Node, statement_node: Prism::Node).returns(String) }
      def convert_type_from_node(node, statement_node:)
        case node
        when Prism::ConstantReadNode
          typescript_type_from_constant_read_node(node, statement_node)
        when Prism::ConstantPathNode
          typescript_type_from_constant_path_node(node)
        when Prism::CallNode
          convert_type_from_call_node(node)
        else
          'z.unknown()'
        end
      end

      # Handles T::Array, T::Boolean, T::Hash, and T::Enum
      #
      # @param node - The node to convert to a Typescript type.
      sig { params(node: Prism::Node).returns(String) }
      def typescript_type_from_constant_path_node(node)
        if T.unsafe(node).parent&.name.to_s == 'T'
          case T.unsafe(node).child.name.to_s
          when 'Boolean'
            'z.boolean()'
          when 'Array'
            if T.unsafe(node).arguments&.arguments&.first
              inner_type =
                convert_type_from_node(
                  T.unsafe(node).arguments.arguments.first,
                  statement_node: node,
                )
              "z.array(#{inner_type})"
            else
              'z.array(z.unknown())'
            end
          when 'Hash'
            args = T.unsafe(node).arguments&.arguments
            if args&.size == 2
              key_type = convert_type_from_node(args[0], statement_node: node)
              value_type = convert_type_from_node(args[1], statement_node: node)
              "z.record(#{key_type}, #{value_type})"
            else
              'z.record(z.unknown(), z.unknown())'
            end
          else
            'z.unknown()'
          end
        else
          "#{T.unsafe(node).full_name}Schema"
        end
      end

      # Handles T.nilable(...) and T.any(...)
      sig { params(node: Prism::CallNode).returns(String) }
      def convert_type_from_call_node(node)
        receiver = T.unsafe(node.receiver)

        if node.name == :nilable && receiver.is_a?(Prism::ConstantReadNode) && receiver.name == :T
          node = T.cast(node, Prism::CallNode)
          arg_node = T.cast(node.arguments, Prism::ArgumentsNode)

          inner_type =
            convert_type_from_node(T.must(arg_node.arguments.first), statement_node: node)

          "#{inner_type}.nullable()"
        elsif node.name == :any && receiver.is_a?(Prism::ConstantReadNode) && receiver.name == :T
          node = T.cast(node, Prism::CallNode)
          arg_node = T.cast(node.arguments, Prism::ArgumentsNode)

          types = arg_node.arguments.map { |arg| convert_type_from_node(arg, statement_node: node) }

          "z.union([#{types.join(', ')}])"
        elsif node.name == :[]
          # Handles T::Array[x, y] or T::Hash[x]
          return 'z.unknown()' unless receiver.is_a?(Prism::ConstantPathNode)

          if T.unsafe(receiver).full_name == 'T::Array'
            inner_type =
              convert_type_from_node(T.unsafe(node).arguments.arguments.first, statement_node: node)
            "z.array(#{inner_type})"
          elsif T.unsafe(receiver).full_name == 'T::Hash'
            args = node.arguments&.arguments
            first_argument = T.must(args&.first)
            last_argument = T.must(args&.last)

            key_type = convert_type_from_node(first_argument, statement_node: node)
            value_type = convert_type_from_node(last_argument, statement_node: node)
            "z.record(#{key_type}, #{value_type})"
          else
            'z.unknown()'
          end
        else
          'z.unknown()'
        end
      end

      sig { params(type_datas: T::Array[TypeData]).returns(String) }
      def generate_typescript(type_datas)
        buffer = String.new("/**\n")
        buffer << "/* This file is generated by Mochitype. Do not edit it by hand.\n"
        buffer << "/**/\n\n"
        buffer << "import { z } from 'zod';\n\n"

        # We need to reverse the order because the parent class is always defined after the child class.
        # We define the child classes first, and then the parents.
        type_datas.reverse.each do |type_data|
          if type_data.base_class_name.include?('T::Enum')
            buffer << "export const #{type_data.typescript_name} = z.enum(#{});\n\n"
          elsif type_data.base_class_name.include?('T::Struct')
            buffer << "export const #{type_data.typescript_name} = z.object({\n"
            buffer << type_data.props.map { |name, type| "  #{name}: #{type}" }.join(",\n")
            buffer << "\n});\n\n"
          else
            raise NotImplementedError, "Unknown type: #{type_data.base_class_name}"
          end

          buffer << "export type #{type_data.name} = z.infer<typeof #{type_data.typescript_name}>;\n\n"
        end

        buffer
      end

      sig { params(input_path: String).returns(String) }
      def determine_output_path(input_path)
        base_name = input_path.sub(%r{^.*#{Mochitype.configuration.watch_path}/}, '')
        output_dir = Mochitype.configuration.output_path
        File.join(output_dir, "#{base_name.delete_suffix('.rb')}.ts")
      end
    end
  end
end
