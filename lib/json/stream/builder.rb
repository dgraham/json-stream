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
        @stack = []
        @keys = []
        @result = nil
      end

      def end_document
        @result = @stack.pop
      end

      def start_object
        @stack.push({})
      end

      def end_object
        return if @stack.size == 1

        node = @stack.pop
        top = @stack[-1]

        case top
        when Hash
          top[@keys.pop] = node
        when Array
          top << node
        end
      end
      alias :end_array :end_object

      def start_array
        @stack.push([])
      end

      def key(key)
        @keys << key
      end

      def value(value)
        top = @stack[-1]
        case top
        when Hash
          top[@keys.pop] = value
        when Array
          top << value
        else
          @stack << value
        end
      end
    end
  end
end
