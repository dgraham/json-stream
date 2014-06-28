# encoding: UTF-8

require 'json/stream'
require 'minitest/autorun'

describe JSON::Stream::Parser do
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
      skip
      expected = [[:value, nil]]
      assert_equal expected, events('null')
    end

    it 'parses a false value document' do
      skip
      expected = [[:value, false]]
      assert_equal expected, events('false')
    end

    it 'parses a true value document' do
      skip
      expected = [[:value, true]]
      assert_equal expected, events('true')
    end

    it 'parses a string document' do
      skip
      expected = [[:value, "test"]]
      assert_equal expected, events('"test"')
    end

    it 'parses an integer value document' do
      skip 'need parser#finish method'
      expected = [[:value, 12]]
      assert_equal(expected, events('12'))
    end

    it 'parses a float value document' do
      skip 'need parser#finish method'
      expected = [[:value, 12.1]]
      assert_equal(expected, events('12.1'))
    end

    it 'parses a value document with leading whitespace' do
      skip
      expected = [[:value, false]]
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

    # Whitespace around tokens should be ignored. Whitespace within strings
    # must be preserved.
    it 'ignores whitespace around tokens' do
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
      assert_equal(expected, events(json))
    end

    it 'rejects vertical tab whitespace' do
      json = "[1,\v 2]"
      expected = [:start_document, :start_array, [:value, 1], :error]
      assert_equal(expected, events(json))
    end

    it 'rejects partial keyword tokens' do
      expected = [:start_document, :start_array, :error]
      ['[tru]', '[fal]', '[nul,true]', '[fals1]'].each do |json|
        assert_equal expected, events(json)
      end

      expected = [:start_document, :start_array, [:value, true], :end_array, :end_document]
      assert_equal expected, events('[true]')

      expected = [:start_document, :start_array, [:value, true], [:value, nil], :end_array, :end_document]
      assert_equal expected, events('[true, null]')
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

    it 'parses positive exponent integers' do
      expected = [:start_document, :start_array, [:value, 212], :end_array, :end_document]
      assert_equal expected, events('[2.12e2]')
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
    it 'rejects invalid escape characters' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events(%q{ [" \\a "] })
    end

    it 'parses two-character escapes' do
      expected = [:start_document, :start_array, [:value, "\" \\ / \b \f \n \r \t"], :end_array, :end_document]
      assert_equal expected, events('["\" \\\ \/ \b \f \n \r \t"]')

      expected = [:start_document, :start_array, [:value, "\"\\/\b\f\n\r\t"], :end_array, :end_document]
      assert_equal expected, events('["\"\\\\/\b\f\n\r\t"]')

      expected = [:start_document, :start_array, [:value, "\"t\\b/f\bn\f/\nn\rr\t"], :end_array, :end_document]
      assert_equal expected, events('["\"t\\\b\/f\bn\f/\nn\rr\t"]')
    end

    it 'rejects control character in array' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events("[\" \u0000 \"]")
    end

    it 'rejects control character in object' do
      expected = [:start_document, :start_object, :error]
      assert_equal expected, events("{\" \u0000 \":12}")
    end

    it 'parses non-control character' do
      expected = [:start_document, :start_array, [:value, " \u007F "], :end_array, :end_document]
      assert_equal expected, events("[\" \u007f \"]")
    end

    it 'rejects invalid unicode escapes' do
      expected = [:start_document, :start_array, :error]
      [%q{ [" \\u "] }, %q{ [" \\u2 "]}, %q{ [" \\u26 "]}, %q{ [" \\u260 "]}].each do |json|
        assert_equal expected, events(json)
      end
    end

    it 'parses unicode escapes' do
      expected = [:start_document, :start_array, [:value, "\u2603"], :end_array, :end_document]
      assert_equal expected, events(%q{ ["\\u2603"] })

      expected = [:start_document, :start_array, [:value, "snow\u2603 man"], :end_array, :end_document]
      assert_equal expected, events(%q{ ["snow\\u2603 man"] })

      expected = [:start_document, :start_array, [:value, "snow\u26033 man"], :end_array, :end_document]
      assert_equal expected, events(%q{ ["snow\\u26033 man"] })

      expected = [:start_document, :start_object, [:key, "snow\u26033 man"], [:value, 1], :end_object, :end_document]
      assert_equal expected, events(%q{ {"snow\\u26033 man": 1} })
    end

    it 'parses unicode escapes with surrogate pairs' do
      expected = [:start_document, :start_array, :error]
      assert_equal(expected, events(%q{ ["\uD834"] }))
      assert_equal(expected, events(%q{ ["\uD834\uD834"] }))
      assert_equal(expected, events(%q{ ["\uDD1E"] }))
      assert_equal(expected, events(%q{ ["\uDD1E\uDD1E"] }))

      expected = [
        :start_document,
          :start_object,
            [:key, "\u{1D11E}"],
            [:value, "g\u{1D11E}clef"],
          :end_object,
        :end_document
      ]
      assert_equal(expected, events(%q{ {"\uD834\uDD1E": "g\uD834\uDD1Eclef"} }))
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
    it 'parses single byte utf8' do
      expected = [:start_document, :start_array, [:value, "test"], :end_array, :end_document]
      assert_equal expected, events('["test"]')
    end

    it 'parses full two byte utf8' do
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
    it 'rejects a partial two byte utf8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('["\xC3"]')
    end

    it 'parses valid two byte utf 8 string' do
      expected = [:start_document, :start_array, [:value, 'é'], :end_array, :end_document]
      assert_equal expected, events("[\"\xC3\xA9\"]")
    end

    it 'parses full three byte utf8 string' do
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

    it 'rejects one byte of three byte utf8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('["\xE2"]')
    end

    it 'rejects two bytes of three byte utf8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('["\xE2\x98"]')
    end

    it 'parses full three byte utf8 string' do
      expected = [:start_document, :start_array, [:value, "\u2603"], :end_array, :end_document]
      assert_equal expected, events("[\"\xE2\x98\x83\"]")
    end

    it 'parses full four byte utf8 string' do
      expected = [
        :start_document,
          :start_array,
            [:value, "\u{10102} check mark"],
          :end_array,
        :end_document
      ]
      assert_equal expected, events("[\"\u{10102} check mark\"]")
    end

    it 'rejects one byte of four byte utf8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('["\xF0"]')
    end

    it 'rejects two bytes of four byte utf8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('["\xF0\x90"]')
    end

    it 'rejects three bytes of four byte utf8 string' do
      expected = [:start_document, :start_array, :error]
      assert_equal expected, events('["\xF0\x90\x84"]')
    end

    it 'parses full four byte utf8 string' do
      expected = [:start_document, :start_array, [:value, "\u{10102}"], :end_array, :end_document]
      assert_equal expected, events("[\"\xF0\x90\x84\x82\"]")
    end
  end

  it 'parses a json text from the module' do
    json = "[1,2,3]"
    obj = JSON::Stream::Parser.parse(json)
    assert_equal [1,2,3], obj
  end

  it 'registers observers in initializer block' do
    events = []
    parser = JSON::Stream::Parser.new do
      start_document { events << :start_document }
      end_document   { events << :end_document }
      start_object   { events << :start_object }
      end_object     { events << :end_object }
      key            {|k| events << [:key, k] }
      value          {|v| events << [:value, v] }
    end
    parser << '{"key":12}'
    expected = [:start_document, :start_object, [:key, "key"], [:value, 12], :end_object, :end_document]
    assert_equal expected, events
  end

  private

  # Run a worst case, one character at a time, parse against the
  # JSON string and return a list of events generated by the parser.
  # A special :error event is included if the parser threw an exception.
  #
  # json - The String to parse.
  #
  # Returns an Events instance.
  def events(json)
    parser = JSON::Stream::Parser.new
    collector = Events.new(parser)
    begin
      json.each_char {|ch| parser << ch }
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
