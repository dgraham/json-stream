# encoding: UTF-8

module JSON
  module Stream

    # A character buffer that expects a UTF-8 encoded stream of bytes.
    # This handles truncated multi-byte characters properly so we can just
    # feed it binary data and receive a properly formatted UTF-8 String as
    # output. See here for UTF-8 parsing details:
    # http://en.wikipedia.org/wiki/UTF-8
    # http://tools.ietf.org/html/rfc3629#section-3
    class Buffer
      def initialize
        @state, @buf, @need = :start, [], 0
      end

      # Fill the buffer with a String of binary UTF-8 encoded bytes. Returns
      # as much of the data in a UTF-8 String as we have. Truncated multi-byte
      # characters are saved in the buffer until the next call to this method
      # where we expect to receive the rest of the multi-byte character.
      def <<(data)
        bytes = []
        data.bytes.each do |b|
          case @state
          when :start
            if b < 128
              bytes << b
            elsif b >= 192
              @state = :multi_byte
              @buf << b
              @need = case
                when b >= 240 then 4
                when b >= 224 then 3
                when b >= 192 then 2 end
            else
              error('Expected start of multi-byte or single byte char')
            end
          when :multi_byte
            if b > 127 && b < 192
              @buf << b
              if @buf.size == @need
                bytes += @buf.slice!(0, @buf.size)
                @state = :start
              end
            else
              error('Expected continuation byte')
            end
          end
        end
        encoded = bytes.pack('C*').force_encoding(Encoding::UTF_8)
        error('Invalid UTF-8 byte sequence') unless encoded.valid_encoding?
        encoded
      end

      private

      def error(message)
        raise ParserError, message
      end
    end

  end
end
