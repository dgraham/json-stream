require 'json/stream'
require 'minitest/autorun'

describe JSON::Stream::Parser do
  subject { JSON::Stream::Parser.new }

  describe 'parsing a document' do
    it 'rejects documents containing bad start character' do
      expected = [:error]
      assert_equal expected, events('a')
    end

    it 'rejects documents starting with period' do
      expected = [:error]
      assert_equal expected, events('.')
    end

    it 'parses a null value document' do
      expected = [:start_document, [:value, nil], :end_document]
      assert_equal expected, events('null')
    end

    it 'parses a false value document' do
      expected = [:start_document, [:value, false], :end_document]
      assert_equal expected, events('false')
    end

    it 'parses a true value document' do
      expected = [:start_document, [:value, true], :end_document]
      assert_equal expected, events('true')
    end

    it 'parses a string document' do
      expected = [:start_document, [:value, "test"], :end_document]
      assert_equal expected, events('"test"')
    end

    it 'parses a single digit integer value document' do
      expected = [:start_document, [:value, 2], :end_document]
      events = events('2', subject)
      assert events.empty?
      subject.finish
      assert_equal expected, events
    end

    it 'parses a multiple digit integer value document' do
      expected = [:start_document, [:value, 12], :end_document]
      events = events('12', subject)
      assert events.empty?
      subject.finish
      assert_equal expected, events
    end

    it 'parses a zero literal document' do
      expected = [:start_document, [:value, 0], :end_document]
      events = events('0', subject)
      assert events.empty?
      subject.finish
      assert_equal expected, events
    end

    it 'parses a negative integer document' do
      expected = [:start_document, [:value, -1], :end_document]
      events = events('-1', subject)
      assert events.empty?
      subject.finish
      assert_equal expected, events
    end

    it 'parses an exponent literal document' do
      expected = [:start_document, [:value, 200.0], :end_document]
      events = events('2e2', subject)
      assert events.empty?
      subject.finish
      assert_equal expected, events
    end

    it 'parses a float value document' do
      expected = [:start_document, [:value, 12.1], :end_document]
      events = events('12.1', subject)
      assert events.empty?
      subject.finish
      assert_equal expected, events
    end

    it 'parses a value document with leading whitespace' do
      expected = [:start_document, [:value, false], :end_document]
      assert_equal expected, events('  false  ')
    end

    it 'parses array documents' do
      expected = [:start_document, :start_array, :end_array, :end_document]
      assert_equal expected, events('[]')
      assert_equal expected, events('[ ]')
      assert_equal expected, events(' [] ')
      assert_equal expected, events(' [ ] ')
    end

    it 'parses object documents' do
      expected = [:start_document, :start_object, :end_object, :end_document]
      assert_equal expected, events('{}')
      assert_equal expected, events('{ }')
      assert_equal expected, events(' {} ')
      assert_equal expected, events(' { } ')
    end

    it 'rejects documents with trailing characters' do
      expected = [:start_document, :start_object, :end_object, :end_document, :error]
      assert_equal expected, events('{}a')
      assert_equal expected, events('{ } 12')
      assert_equal expected, events(' {} false')
      assert_equal expected, events(' { }, {}')
    end

    it 'ignores whitespace around tokens, preserves it within strings' do
      json = %Q{
        { " key 1 " : \t [
          1, 2, " my string ",\r
          false, true, null ]
        }
      }
      expected = [
        :start_document,
          :start_object,
            [:key, " key 1 "],
            :start_array,
              [:value, 1],
              [:value, 2],
              [:value, " my string "],
              [:value, false],
              [:value, true],
              [:value, nil],
            :end_array,
          :end_object,
        :end_document
      ]
      assert_equal expected, events(json)
    end

    it 'rejects form feed whitespace' do
      json = "[1,\f 2]"
      expected = [:start_document, :start_array, [:value, 1], :error]
      assert_equal expected, events(json)
    end

    it 'rejects vertical tab whitespace' do
      json = "[1,\v 2]"
      expected = [:start_document, :start_array, [:value, 1], :error]
      assert_equal expected, events(json)
    end

    it 'rejects partial keyword tokens' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('[tru]')
      assert_equal expected, events('[fal]')
      assert_equal expected, events('[nul,true]')
      assert_equal expected, events('[fals1]')
    end

    it 'rejects scrambled keyword tokens' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('[ture]')
      assert_equal expected, events('[fales]')
      assert_equal expected, events('[nlul]')
    end

    it 'parses single keyword tokens' do
      expected = [:start_document, :start_array, [:value, true], :end_array, :end_document]
      assert_equal expected, events('[true]')
    end

    it 'parses keywords in series' do
      expected = [:start_document, :start_array, [:value, true], [:value, nil], :end_array, :end_document]
      assert_equal expected, events('[true, null]')
    end
  end

  describe 'finishing the parse' do
    it 'rejects finish with no json data provided' do
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial null keyword' do
      subject << 'nul'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial true keyword' do
      subject << 'tru'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial false keyword' do
      subject << 'fals'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial float literal' do
      subject << '42.'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial exponent' do
      subject << '42e'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects malformed exponent' do
      subject << '42e+'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial negative number' do
      subject << '-'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial string literal' do
      subject << '"test'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial object ending in literal value' do
      subject << '{"test": 42'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'rejects partial array ending in literal value' do
      subject << '[42'
      assert_raises(JSON::Stream::ParserError) { subject.finish }
    end

    it 'does nothing on subsequent finish' do
      begin
        subject << 'false'
        subject.finish
        subject.finish
      rescue
        fail 'raised unexpected error'
      end
    end
  end

  describe 'parsing number tokens' do
    it 'rejects invalid negative numbers' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('[-]')

      expected = [:start_document, :start_array, [:value, 1], :error]
      assert_equal expected, events('[1-0]')
    end

    it 'parses integer zero' do
      expected = [:start_document, :start_array, [:value, 0], :end_array, :end_document]
      assert_equal expected, events('[0]')
      assert_equal expected, events('[-0]')
    end

    it 'parses float zero' do
      expected = [:start_document, :start_array, [:value, 0.0], :end_array, :end_document]
      assert_equal expected, events('[0.0]')
      assert_equal expected, events('[-0.0]')
    end

    it 'rejects multi zero' do
      expected = [:start_document, :start_array, [:value, 0], :error]
      assert_equal expected, events('[00]')
      assert_equal expected, events('[-00]')
    end

    it 'rejects integers that start with zero' do
      expected = [:start_document, :start_array, [:value, 0], :error]
      assert_equal expected, events('[01]')
      assert_equal expected, events('[-01]')
    end

    it 'parses integer tokens' do
      expected = [:start_document, :start_array, [:value, 1], :end_array, :end_document]
      assert_equal expected, events('[1]')

      expected = [:start_document, :start_array, [:value, -1], :end_array, :end_document]
      assert_equal expected, events('[-1]')

      expected = [:start_document, :start_array, [:value, 123], :end_array, :end_document]
      assert_equal expected, events('[123]')

      expected = [:start_document, :start_array, [:value, -123], :end_array, :end_document]
      assert_equal expected, events('[-123]')
    end

    it 'parses float tokens' do
      expected = [:start_document, :start_array, [:value, 1.0], :end_array, :end_document]
      assert_equal expected, events('[1.0]')
      assert_equal expected, events('[1.00]')
    end

    it 'parses negative floats' do
      expected = [:start_document, :start_array, [:value, -1.0], :end_array, :end_document]
      assert_equal expected, events('[-1.0]')
      assert_equal expected, events('[-1.00]')
    end

    it 'parses multi-digit floats' do
      expected = [:start_document, :start_array, [:value, 123.012], :end_array, :end_document]
      assert_equal expected, events('[123.012]')
      assert_equal expected, events('[123.0120]')
    end

    it 'parses negative multi-digit floats' do
      expected = [:start_document, :start_array, [:value, -123.012], :end_array, :end_document]
      assert_equal expected, events('[-123.012]')
      assert_equal expected, events('[-123.0120]')
    end

    it 'rejects floats missing leading zero' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('[.1]')
      assert_equal expected, events('[-.1]')
      assert_equal expected, events('[.01]')
      assert_equal expected, events('[-.01]')
    end

    it 'rejects float missing fraction' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('[.]')
      assert_equal expected, events('[..]')
      assert_equal expected, events('[0.]')
      assert_equal expected, events('[12.]')
    end

    it 'parses zero with implicit positive exponent as float' do
      expected = [:start_document, :start_array, [:value, 0.0], :end_array, :end_document]
      events = events('[0e2]')
      assert_equal expected, events
      assert_kind_of Float, events[2][1]
    end

    it 'parses zero with explicit positive exponent as float' do
      expected = [:start_document, :start_array, [:value, 0.0], :end_array, :end_document]
      events = events('[0e+2]')
      assert_equal expected, events
      assert_kind_of Float, events[2][1]
    end

    it 'parses zero with negative exponent as float' do
      expected = [:start_document, :start_array, [:value, 0.0], :end_array, :end_document]
      events = events('[0e-2]')
      assert_equal expected, events
      assert_kind_of Float, events[2][1]
    end

    it 'parses positive exponent integers as floats' do
      expected = [:start_document, :start_array, [:value, 212.0], :end_array, :end_document]

      events = events('[2.12e2]')
      assert_equal expected, events('[2.12e2]')
      assert_kind_of Float, events[2][1]

      assert_equal expected, events('[2.12e02]')
      assert_equal expected, events('[2.12e+2]')
      assert_equal expected, events('[2.12e+02]')
    end

    it 'parses positive exponent floats' do
      expected = [:start_document, :start_array, [:value, 21.2], :end_array, :end_document]
      assert_equal expected, events('[2.12e1]')
      assert_equal expected, events('[2.12e01]')
      assert_equal expected, events('[2.12e+1]')
      assert_equal expected, events('[2.12e+01]')
    end

    it 'parses negative exponent' do
      expected = [:start_document, :start_array, [:value, 0.0212], :end_array, :end_document]
      assert_equal expected, events('[2.12e-2]')
      assert_equal expected, events('[2.12e-02]')
      assert_equal expected, events('[2.12e-2]')
      assert_equal expected, events('[2.12e-02]')
    end

    it 'parses zero exponent floats' do
      expected = [:start_document, :start_array, [:value, 2.12], :end_array, :end_document]
      assert_equal expected, events('[2.12e0]')
      assert_equal expected, events('[2.12e00]')
      assert_equal expected, events('[2.12e-0]')
      assert_equal expected, events('[2.12e-00]')
    end

    it 'parses zero exponent integers' do
      expected = [:start_document, :start_array, [:value, 2.0], :end_array, :end_document]
      assert_equal expected, events('[2e0]')
      assert_equal expected, events('[2e00]')
      assert_equal expected, events('[2e-0]')
      assert_equal expected, events('[2e-00]')
    end

    it 'rejects missing exponent' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('[e]')
      assert_equal expected, events('[1e]')
      assert_equal expected, events('[1e-]')
      assert_equal expected, events('[1e--]')
      assert_equal expected, events('[1e+]')
      assert_equal expected, events('[1e++]')
      assert_equal expected, events('[0.e]')
      assert_equal expected, events('[10.e]')
    end

    it 'rejects float with trailing character' do
      expected = [:start_document, :start_array, [:value, 0.0], :error]
      assert_equal expected, events('[0.0q]')
    end

    it 'rejects integer with trailing character' do
      expected = [:start_document, :start_array, [:value, 1], :error]
      assert_equal expected, events('[1q]')
    end
  end

  describe 'parsing string tokens' do
    describe 'parsing two-character escapes' do
      it 'rejects invalid escape characters' do
        expected = [:start_document, :start_array, :error]
        assert_equal expected, events('["\\a"]')
      end

      it 'parses quotation mark' do
        expected = [:start_document, :start_array, [:value, "\""], :end_array, :end_document]
        assert_equal expected, events('["\""]')
      end

      it 'parses reverse solidus' do
        expected = [:start_document, :start_array, [:value, "\\"], :end_array, :end_document]
        assert_equal expected, events('["\\\"]')
      end

      it 'parses solidus' do
        expected = [:start_document, :start_array, [:value, "/"], :end_array, :end_document]
        assert_equal expected, events('["\/"]')
      end

      it 'parses backspace' do
        expected = [:start_document, :start_array, [:value, "\b"], :end_array, :end_document]
        assert_equal expected, events('["\b"]')
      end

      it 'parses form feed' do
        expected = [:start_document, :start_array, [:value, "\f"], :end_array, :end_document]
        assert_equal expected, events('["\f"]')
      end

      it 'parses line feed' do
        expected = [:start_document, :start_array, [:value, "\n"], :end_array, :end_document]
        assert_equal expected, events('["\n"]')
      end

      it 'parses carriage return' do
        expected = [:start_document, :start_array, [:value, "\r"], :end_array, :end_document]
        assert_equal expected, events('["\r"]')
      end

      it 'parses tab' do
        expected = [:start_document, :start_array, [:value, "\t"], :end_array, :end_document]
        assert_equal expected, events('["\t"]')
      end

      it 'parses a series of escapes with whitespace' do
        expected = [:start_document, :start_array, [:value, "\" \\ / \b \f \n \r \t"], :end_array, :end_document]
        assert_equal expected, events('["\" \\\ \/ \b \f \n \r \t"]')
      end

      it 'parses a series of escapes without whitespace' do
        expected = [:start_document, :start_array, [:value, "\"\\/\b\f\n\r\t"], :end_array, :end_document]
        assert_equal expected, events('["\"\\\\/\b\f\n\r\t"]')
      end

      it 'parses a series of escapes with duplicate characters between them' do
        expected = [:start_document, :start_array, [:value, "\"t\\b/f\bn\f/\nn\rr\t"], :end_array, :end_document]
        assert_equal expected, events('["\"t\\\b\/f\bn\f/\nn\rr\t"]')
      end
    end

    describe 'parsing control characters' do
      it 'rejects control character in array' do
        expected = [:start_document, :start_array, :error]
        assert_equal expected, events("[\" \u0000 \"]")
      end

      it 'rejects control character in object' do
        expected = [:start_document, :start_object, :error]
        assert_equal expected, events("{\" \u0000 \":12}")
      end

      it 'parses escaped control character' do
        expected = [:start_document, :start_array, [:value, "\u0000"], :end_array, :end_document]
        assert_equal expected, events('["\\u0000"]')
      end

      it 'parses escaped control character in object key' do
        expected = [:start_document, :start_object, [:key, "\u0000"], [:value, 12], :end_object, :end_document]
        assert_equal expected, events('{"\\u0000": 12}')
      end

      it 'parses non-control character' do
        # del ascii 127 is allowed unescaped in json
        expected = [:start_document, :start_array, [:value, " \u007F "], :end_array, :end_document]
        assert_equal expected, events("[\" \u007f \"]")
      end
    end

    describe 'parsing unicode escape sequences' do
      it 'parses escaped ascii character' do
        a = "\x61"
        escaped = '\u0061'
        expected = [:start_document, :start_array, [:value, a], :end_array, :end_document]
        assert_equal expected, events('["' + escaped + '"]')
      end

      it 'parses un-escaped raw unicode' do
        # U+1F602 face with tears of joy
        face = "\xf0\x9f\x98\x82"
        expected = [:start_document, :start_array, [:value, face], :end_array, :end_document]
        assert_equal expected, events('["' + face + '"]')
      end

      it 'parses escaped unicode surrogate pairs' do
        # U+1F602 face with tears of joy
        face = "\xf0\x9f\x98\x82"
        escaped = '\uD83D\uDE02'
        expected = [:start_document, :start_array, [:value, face], :end_array, :end_document]
        assert_equal expected, events('["' + escaped + '"]')
      end

      it 'rejects partial unicode escapes' do
        expected = [:start_document, :start_array, :error]
        assert_equal expected, events('[" \\u "]')
        assert_equal expected, events('[" \\u2 "]')
        assert_equal expected, events('[" \\u26 "]')
        assert_equal expected, events('[" \\u260 "]')
      end

      it 'parses unicode escapes' do
        # U+2603 snowman
        snowman = "\xe2\x98\x83"
        escaped = '\u2603'

        expected = [:start_document, :start_array, [:value, snowman], :end_array, :end_document]
        assert_equal expected, events('["' + escaped + '"]')

        expected = [:start_document, :start_array, [:value, 'snow' + snowman + ' man'], :end_array, :end_document]
        assert_equal expected, events('["snow' + escaped + ' man"]')

        expected = [:start_document, :start_array, [:value, 'snow' + snowman + '3 man'], :end_array, :end_document]
        assert_equal expected, events('["snow' + escaped + '3 man"]')

        expected = [:start_document, :start_object, [:key, 'snow' + snowman + '3 man'], [:value, 1], :end_object, :end_document]
        assert_equal expected, events('{"snow\\u26033 man": 1}')
      end
    end

    describe 'parsing unicode escapes with surrogate pairs' do
      it 'rejects missing second pair' do
        expected = [:start_document, :start_array, :error]
        assert_equal expected, events('["\uD834"]')
      end

      it 'rejects missing first pair' do
        expected = [:start_document, :start_array, :error]
        assert_equal expected, events('["\uDD1E"]')
      end

      it 'rejects double first pair' do
        expected = [:start_document, :start_array, :error]
        assert_equal expected, events('["\uD834\uD834"]')
      end

      it 'rejects double second pair' do
        expected = [:start_document, :start_array, :error]
        assert_equal expected, events('["\uDD1E\uDD1E"]')
      end

      it 'rejects reversed pair' do
        expected = [:start_document, :start_array, :error]
        assert_equal expected, events('["\uDD1E\uD834"]')
      end

      it 'parses correct pairs in object keys and values' do
        # U+1D11E G-Clef
        clef = "\xf0\x9d\x84\x9e"
        expected = [
          :start_document,
            :start_object,
              [:key, clef],
              [:value, "g\u{1D11E}clef"],
            :end_object,
          :end_document
        ]
        assert_equal expected, events(%q{ {"\uD834\uDD1E": "g\uD834\uDD1Eclef"} })
      end
    end
  end

  describe 'parsing arrays' do
    it 'rejects trailing comma' do
      expected = [:start_document, :start_array, [:value, 12], :error]
      assert_equal expected, events('[12, ]')
    end

    it 'parses nested empty array' do
      expected = [:start_document, :start_array, :start_array, :end_array, :end_array, :end_document]
      assert_equal expected, events('[[]]')
    end

    it 'parses nested array with value' do
      expected = [:start_document, :start_array, :start_array, [:value, 2.1], :end_array, :end_array, :end_document]
      assert_equal expected, events('[[ 2.10 ]]')
    end

    it 'rejects malformed arrays' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('[}')
      assert_equal expected, events('[,]')
      assert_equal expected, events('[, 12]')
    end

    it 'rejects malformed nested arrays' do
      expected = [:start_document, :start_array, :start_array, :error]
      assert_equal(expected, events('[[}]'))
      assert_equal expected, events('[[}]')
      assert_equal expected, events('[[,]]')
    end

    it 'rejects malformed array value lists' do
      expected = [:start_document, :start_array, [:value, "test"], :error]
      assert_equal expected, events('["test"}')
      assert_equal expected, events('["test",]')
      assert_equal expected, events('["test" "test"]')
      assert_equal expected, events('["test" 12]')
    end

    it 'parses array with value' do
      expected = [:start_document, :start_array, [:value, "test"], :end_array, :end_document]
      assert_equal expected, events('["test"]')
    end

    it 'parses array with value list' do
      expected = [
        :start_document,
          :start_array,
            [:value, 1],
            [:value, 2],
            [:value, nil],
            [:value, 12.1],
            [:value, "test"],
          :end_array,
        :end_document
      ]
      assert_equal expected, events('[1,2, null, 12.1,"test"]')
    end
  end

  describe 'parsing objects' do
    it 'rejects malformed objects' do
      expected = [:start_document, :start_object, :error]
      assert_equal expected, events('{]')
      assert_equal expected, events('{:}')
    end

    it 'parses single key object' do
      expected = [:start_document, :start_object, [:key, "key 1"], [:value, 12], :end_object, :end_document]
      assert_equal expected, events('{"key 1" : 12}')
    end

    it 'parses object key value list' do
      expected = [
        :start_document,
          :start_object,
            [:key, "key 1"], [:value, 12],
            [:key, "key 2"], [:value, "two"],
          :end_object,
        :end_document
      ]
      assert_equal expected, events('{"key 1" : 12, "key 2":"two"}')
    end

    it 'rejects object key with no value' do
      expected = [
        :start_document,
          :start_object,
            [:key, "key"],
            :start_array,
              [:value, nil],
              [:value, false],
              [:value, true],
            :end_array,
            [:key, "key 2"],
          :error
      ]
      assert_equal expected, events('{"key": [ null , false , true ] ,"key 2"}')
    end

    it 'rejects object with trailing comma' do
      expected = [:start_document, :start_object, [:key, "key 1"], [:value, 12], :error]
      assert_equal expected, events('{"key 1" : 12,}')
    end
  end

  describe 'parsing unicode bytes' do
    it 'parses single byte utf-8' do
      expected = [:start_document, :start_array, [:value, "test"], :end_array, :end_document]
      assert_equal expected, events('["test"]')
    end

    it 'parses full two byte utf-8' do
      expected = [
        :start_document,
          :start_array,
            [:value, "résumé"],
            [:value, "éé"],
          :end_array,
        :end_document
      ]
      assert_equal expected, events("[\"résumé\", \"é\xC3\xA9\"]")
    end

    # Parser should throw an error when only one byte of a two byte character
    # is available. The \xC3 byte is the first byte of the é character.
    it 'rejects a partial two byte utf-8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events("[\"\xC3\"]")
    end

    it 'parses valid two byte utf-8 string' do
      expected = [:start_document, :start_array, [:value, 'é'], :end_array, :end_document]
      assert_equal expected, events("[\"\xC3\xA9\"]")
    end

    it 'parses full three byte utf-8 string' do
      expected = [
        :start_document,
          :start_array,
            [:value, "snow\u2603man"],
            [:value, "\u2603\u2603"],
          :end_array,
        :end_document
      ]
      assert_equal expected, events("[\"snow\u2603man\", \"\u2603\u2603\"]")
    end

    it 'rejects one byte of three byte utf-8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events("[\"\xE2\"]")
    end

    it 'rejects two bytes of three byte utf-8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events("[\"\xE2\x98\"]")
    end

    it 'parses full three byte utf-8 string' do
      expected = [:start_document, :start_array, [:value, "\u2603"], :end_array, :end_document]
      assert_equal expected, events("[\"\xE2\x98\x83\"]")
    end

    it 'parses full four byte utf-8 string' do
      expected = [
        :start_document,
          :start_array,
            [:value, "\u{10102} check mark"],
          :end_array,
        :end_document
      ]
      assert_equal expected, events("[\"\u{10102} check mark\"]")
    end

    it 'rejects one byte of four byte utf-8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events("[\"\xF0\"]")
    end

    it 'rejects two bytes of four byte utf-8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events("[\"\xF0\x90\"]")
    end

    it 'rejects three bytes of four byte utf-8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events("[\"\xF0\x90\x84\"]")
    end

    it 'parses full four byte utf-8 string' do
      expected = [:start_document, :start_array, [:value, "\u{10102}"], :end_array, :end_document]
      assert_equal expected, events("[\"\xF0\x90\x84\x82\"]")
    end
  end

  describe 'parsing json text from the module' do
    it 'parses an array document' do
      result = JSON::Stream::Parser.parse('[1,2,3]')
      assert_equal [1, 2, 3], result
    end

    it 'parses a true keyword literal document' do
      result = JSON::Stream::Parser.parse('true')
      assert_equal true, result
    end

    it 'parses a false keyword literal document' do
      result = JSON::Stream::Parser.parse('false')
      assert_equal false, result
    end

    it 'parses a null keyword literal document' do
      result = JSON::Stream::Parser.parse('null')
      assert_nil result
    end

    it 'parses a string literal document' do
      result = JSON::Stream::Parser.parse('"hello"')
      assert_equal 'hello', result
    end

    it 'parses an integer literal document' do
      result = JSON::Stream::Parser.parse('42')
      assert_equal 42, result
    end

    it 'parses a float literal document' do
      result = JSON::Stream::Parser.parse('42.12')
      assert_equal 42.12, result
    end

    it 'rejects a partial float literal document' do
      assert_raises(JSON::Stream::ParserError) do
        JSON::Stream::Parser.parse('42.')
      end
    end

    it 'rejects a partial document' do
      assert_raises(JSON::Stream::ParserError) do
        JSON::Stream::Parser.parse('{')
      end
    end

    it 'rejects an empty document' do
      assert_raises(JSON::Stream::ParserError) do
        JSON::Stream::Parser.parse('')
      end
    end
  end

  it 'registers observers in initializer block' do
    events = []
    parser = JSON::Stream::Parser.new do
      start_document { events << :start_document }
      end_document   { events << :end_document }
      start_object   { events << :start_object }
      end_object     { events << :end_object }
      key            { |k| events << [:key, k] }
      value          { |v| events << [:value, v] }
    end
    parser << '{"key":12}'
    expected = [:start_document, :start_object, [:key, "key"], [:value, 12], :end_object, :end_document]
    assert_equal expected, events
  end

  private

  # Run a worst case, one byte at a time, parse against the JSON string and
  # return a list of events generated by the parser. A special :error event is
  # included if the parser threw an exception.
  #
  # json   - The String to parse.
  # parser - The optional Parser instance to use.
  #
  # Returns an Events instance.
  def events(json, parser = nil)
    parser ||= JSON::Stream::Parser.new
    collector = Events.new(parser)
    begin
      json.each_byte { |byte| parser << [byte].pack('C') }
    rescue JSON::Stream::ParserError
      collector.error
    end
    collector.events
  end

  # Dynamically map methods in this class to parser callback methods
  # so we can collect parser events for inspection by test cases.
  class Events
    METHODS = %w[start_document end_document start_object end_object start_array end_array key value]

    attr_reader :events

    def initialize(parser)
      @events = []
      METHODS.each do |name|
        parser.send(name, &method(name))
      end
    end

    METHODS.each do |name|
      define_method(name) do |*args|
        @events << (args.empty? ? name.to_sym : [name.to_sym, *args])
      end
    end

    def error
      @events << :error
    end
  end
end
