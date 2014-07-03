# encoding: UTF-8

module JSON
  module Stream
    # A character buffer that expects a UTF-8 encoded stream of bytes.
    # This handles truncated multi-byte characters properly so we can just
    # feed it binary data and receive a properly formatted UTF-8 String as
    # output.
    #
    # More UTF-8 parsing details are available at:
    #
    #   http://en.wikipedia.org/wiki/UTF-8
    #   http://tools.ietf.org/html/rfc3629#section-3
    class Buffer
      def initialize
        @state = :start
        @buf = []
        @need = 0
      end

      # Fill the buffer with a String of binary UTF-8 encoded bytes. Returns
      # as much of the data in a UTF-8 String as we have. Truncated multi-byte
      # characters are saved in the buffer until the next call to this method
      # where we expect to receive the rest of the multi-byte character.
      #
      # data - The partial binary encoded String data.
      #
      # Raises JSON::Stream::ParserError if the UTF-8 byte sequence is malformed.
      #
      # Returns a UTF-8 encoded String.
      def <<(data)
        bytes = []
        data.each_byte do |byte|
          case @state
          when :start
            if byte < 128
              bytes << byte
            elsif byte >= 192
              @state = :multi_byte
              @buf << byte
              @need =
                case
                when byte >= 240 then 4
                when byte >= 224 then 3
                when byte >= 192 then 2
                end
            else
              error('Expected start of multi-byte or single byte char')
            end
          when :multi_byte
            if byte > 127 && byte < 192
              @buf << byte
              if @buf.size == @need
                bytes += @buf.slice!(0, @buf.size)
                @state = :start
              end
            else
              error('Expected continuation byte')
            end
          end
        end
        bytes.pack('C*').force_encoding(Encoding::UTF_8).tap do |str|
          error('Invalid UTF-8 byte sequence') unless str.valid_encoding?
        end
      end

      private

      def error(message)
        raise ParserError, message
      end
    end
  end
end
