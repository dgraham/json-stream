# encoding: UTF-8

module JSON
  module Stream
    # A parser listener that builds a full, in memory, object from a JSON
    # document. This is similar to using the json gem's `JSON.parse` method.
    #
    # Examples
    #
    #   parser = JSON::Stream::Parser.new
    #   builder = JSON::Stream::Builder.new(parser)
    #   parser << '{"answer": 42, "question": false}'
    #   obj = builder.result
    class Builder
      METHODS = %w[start_document end_document start_object end_object start_array end_array key value]

      attr_reader :result

      def initialize(parser)
        METHODS.each do |name|
          parser.send(name, &method(name))
        end
      end

      def start_document
        @stack, @result = [], nil
      end

      def end_document
        @result = @stack.pop.obj
      end

      def start_object
        @stack.push(ObjectNode.new)
      end

      def end_object
        unless @stack.size == 1
          node = @stack.pop
          @stack.last << node.obj
        end
      end
      alias :end_array :end_object

      def start_array
        @stack.push(ArrayNode.new)
      end

      def key(key)
        @stack.last << key
      end

      def value(value)
        @stack.last << value
      end
    end

    class ArrayNode
      attr_reader :obj

      def initialize
        @obj = []
      end

      def <<(node)
        @obj << node
        self
      end
    end

    class ObjectNode
      attr_reader :obj

      def initialize
        @obj, @key = {}, nil
      end

      def <<(node)
        if @key
          @obj[@key] = node
          @key = nil
        else
          @key = node
        end
        self
      end
    end
  end
end
