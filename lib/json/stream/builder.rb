# encoding: UTF-8

module JSON
  module Stream
    # A parser listener that builds a full, in memory, object graph from a
    # JSON document. Typically, we would use the json gem's JSON.parse() method
    # when we have the full JSON document because it's much faster than this.
    # JSON::Stream is typically used when we have a huge JSON document streaming
    # to us and we don't want to hold the entire parsed object in memory.
    # Regardless, this is a good example of how to write parser callbacks.
    #
    # Examples
    #
    #   parser = JSON::Stream::Parser.new
    #   builder = JSON::Stream::Builder.new(parser)
    #   parser << json
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
