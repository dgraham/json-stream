# encoding: UTF-8

require 'json/stream'
require 'test/unit'

class ParserTest < Test::Unit::TestCase

  # JSON documents must start with an array or object container
  # and there must not be any extra data following that container.
  def test_document
    expected = [:error]
    ['a', 'null', 'false', 'true', '12', '  false  '].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_array, :end_array, :end_document]
    ['[]', '[ ]', ' [] ', ' [ ] '].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_object, :end_object, :end_document]
    ['{}', '{ }', ' {} ', ' { } '].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_object, :end_object, :end_document, :error]
    ['{}a', '{ } 12', ' {} false', ' { }, {}'].each do |json|
      assert_equal(expected, events(json))
    end
  end

  # Whitespace around tokens should be ignored. Whitespace within strings
  # must be preserved.
  def test_whitespace
    json = %Q{
      { " key 1 " : \t [
        1, 2, " my string ",\r
        false, true, null ]
      }
    }
    expected = [:start_document, :start_object,
               [:key, " key 1 "],
               :start_array,
               [:value, 1],
               [:value, 2],
               [:value, " my string "],
               [:value, false],
               [:value, true],
               [:value, nil],
               :end_array, :end_object, :end_document]
    assert_equal(expected, events(json))
  end

  def test_disallowed_form_feed_whitespace
    json = "[1,\f 2]"
    expected = [:start_document, :start_array, [:value, 1], :error]
    assert_equal(expected, events(json))
  end

  def test_disallowed_vertical_tab_whitespace
    json = "[1,\v 2]"
    expected = [:start_document, :start_array, [:value, 1], :error]
    assert_equal(expected, events(json))
  end

  def test_keyword
    expected = [:start_document, :start_array, :error]
    ['[tru]', '[fal]', '[nul,true]', '[fals1]'].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_array, [:value, true], :end_array, :end_document]
    assert_equal(expected, events('[true]'))

    expected = [:start_document, :start_array, [:value, true], [:value, nil], :end_array, :end_document]
    assert_equal(expected, events('[true, null]'))
  end

  def test_negative
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('[-]'))

    expected = [:start_document, :start_array, [:value, 1], :error]
    assert_equal(expected, events('[1-0]'))
  end

  def test_int_zero
    expected = [:start_document, :start_array, [:value, 0], :end_array, :end_document]
    assert_equal(expected, events('[0]'))
    assert_equal(expected, events('[-0]'))
  end

  def test_float_zero
    expected = [:start_document, :start_array, [:value, 0.0], :end_array, :end_document]
    assert_equal(expected, events('[0.0]'))
    assert_equal(expected, events('[-0.0]'))
  end

  def test_multi_zero
    expected = [:start_document, :start_array, [:value, 0], :error]
    assert_equal(expected, events('[00]'))
    assert_equal(expected, events('[-00]'))
  end

  def test_starts_with_zero
    expected = [:start_document, :start_array, [:value, 0], :error]
    assert_equal(expected, events('[01]'))
    assert_equal(expected, events('[-01]'))
  end

  def test_int
    expected = [:start_document, :start_array, [:value, 1], :end_array, :end_document]
    assert_equal(expected, events('[1]'))

    expected = [:start_document, :start_array, [:value, -1], :end_array, :end_document]
    assert_equal(expected, events('[-1]'))

    expected = [:start_document, :start_array, [:value, 123], :end_array, :end_document]
    assert_equal(expected, events('[123]'))

    expected = [:start_document, :start_array, [:value, -123], :end_array, :end_document]
    assert_equal(expected, events('[-123]'))
  end

  def test_float
    expected = [:start_document, :start_array, [:value, 1.0], :end_array, :end_document]
    assert_equal(expected, events('[1.0]'))
    assert_equal(expected, events('[1.00]'))

    expected = [:start_document, :start_array, [:value, -1.0], :end_array, :end_document]
    assert_equal(expected, events('[-1.0]'))
    assert_equal(expected, events('[-1.00]'))

    expected = [:start_document, :start_array, [:value, 123.012], :end_array, :end_document]
    assert_equal(expected, events('[123.012]'))
    assert_equal(expected, events('[123.0120]'))

    expected = [:start_document, :start_array, [:value, -123.012], :end_array, :end_document]
    assert_equal(expected, events('[-123.012]'))
    assert_equal(expected, events('[-123.0120]'))
  end

  def test_missing_leading_zero
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('[.1]'))
    assert_equal(expected, events('[-.1]'))
    assert_equal(expected, events('[.01]'))
    assert_equal(expected, events('[-.01]'))
  end

  def test_missing_fraction
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('[.]'))
    assert_equal(expected, events('[..]'))
    assert_equal(expected, events('[0.]'))
    assert_equal(expected, events('[12.]'))
  end

  def test_positive_exponent
    expected = [:start_document, :start_array, [:value, 212], :end_array, :end_document]
    assert_equal(expected, events('[2.12e2]'))
    assert_equal(expected, events('[2.12e02]'))
    assert_equal(expected, events('[2.12e+2]'))
    assert_equal(expected, events('[2.12e+02]'))

    expected = [:start_document, :start_array, [:value, 21.2], :end_array, :end_document]
    assert_equal(expected, events('[2.12e1]'))
    assert_equal(expected, events('[2.12e01]'))
    assert_equal(expected, events('[2.12e+1]'))
    assert_equal(expected, events('[2.12e+01]'))
  end

  def test_negative_exponent
    expected = [:start_document, :start_array, [:value, 0.0212], :end_array, :end_document]
    assert_equal(expected, events('[2.12e-2]'))
    assert_equal(expected, events('[2.12e-02]'))
    assert_equal(expected, events('[2.12e-2]'))
    assert_equal(expected, events('[2.12e-02]'))
  end

  def test_zero_exponent
    expected = [:start_document, :start_array, [:value, 2.12], :end_array, :end_document]
    assert_equal(expected, events('[2.12e0]'))
    assert_equal(expected, events('[2.12e00]'))
    assert_equal(expected, events('[2.12e-0]'))
    assert_equal(expected, events('[2.12e-00]'))

    expected = [:start_document, :start_array, [:value, 2.0], :end_array, :end_document]
    assert_equal(expected, events('[2e0]'))
    assert_equal(expected, events('[2e00]'))
    assert_equal(expected, events('[2e-0]'))
    assert_equal(expected, events('[2e-00]'))
  end

  def test_missing_exponent
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('[e]'))
    assert_equal(expected, events('[1e]'))
    assert_equal(expected, events('[1e-]'))
    assert_equal(expected, events('[1e--]'))
    assert_equal(expected, events('[1e+]'))
    assert_equal(expected, events('[1e++]'))
    assert_equal(expected, events('[0.e]'))
    assert_equal(expected, events('[10.e]'))
  end

  def test_non_digit_end_char
    expected = [:start_document, :start_array, [:value, 0.0], :error]
    assert_equal(expected, events('[0.0q]'))

    expected = [:start_document, :start_array, [:value, 1], :error]
    assert_equal(expected, events('[1q]'))
  end

  def test_string
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events(%q{ [" \\a "] }))

    expected = [:start_document, :start_array, [:value, "\" \\ / \b \f \n \r \t"], :end_array, :end_document]
    assert_equal(expected, events('["\" \\\ \/ \b \f \n \r \t"]'))

    expected = [:start_document, :start_array, [:value, "\"\\/\b\f\n\r\t"], :end_array, :end_document]
    assert_equal(expected, events('["\"\\\\/\b\f\n\r\t"]'))

    expected = [:start_document, :start_array, [:value, "\"t\\b/f\bn\f/\nn\rr\t"], :end_array, :end_document]
    assert_equal(expected, events('["\"t\\\b\/f\bn\f/\nn\rr\t"]'))
  end

  def test_control_char
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events("[\" \u0000 \"]"))

    expected = [:start_document, :start_object, :error]
    assert_equal(expected, events("{\" \u0000 \":12}"))

    expected = [:start_document, :start_array, [:value, " \u007F "], :end_array, :end_document]
    assert_equal(expected, events("[\" \u007f \"]"))
  end

  def test_unicode_escape
    expected = [:start_document, :start_array, :error]
    [%q{ [" \\u "] }, %q{ [" \\u2 "]}, %q{ [" \\u26 "]}, %q{ [" \\u260 "]}].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_array, [:value, "\u2603"], :end_array, :end_document]
    assert_equal(expected, events(%q{ ["\\u2603"] }))

    expected = [:start_document, :start_array, [:value, "snow\u2603 man"], :end_array, :end_document]
    assert_equal(expected, events(%q{ ["snow\\u2603 man"] }))

    expected = [:start_document, :start_array, [:value, "snow\u26033 man"], :end_array, :end_document]
    assert_equal(expected, events(%q{ ["snow\\u26033 man"] }))

    expected = [:start_document, :start_object, [:key, "snow\u26033 man"], [:value, 1], :end_object, :end_document]
    assert_equal(expected, events(%q{ {"snow\\u26033 man": 1} }))
  end

  def test_unicode_escape_surrogate_pairs
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events(%q{ ["\uD834"] }))
    assert_equal(expected, events(%q{ ["\uD834\uD834"] }))
    assert_equal(expected, events(%q{ ["\uDD1E"] }))
    assert_equal(expected, events(%q{ ["\uDD1E\uDD1E"] }))

    expected = [:start_document, :start_object, [:key, "\u{1D11E}"],
               [:value, "g\u{1D11E}clef"], :end_object, :end_document]
    assert_equal(expected, events(%q{ {"\uD834\uDD1E": "g\uD834\uDD1Eclef"} }))
  end

  def test_array_trailing_comma
    expected = [:start_document, :start_array, [:value, 12], :error]
    assert_equal(expected, events('[12, ]'))
  end

  def test_nested_array
    expected = [:start_document, :start_array, :start_array, :end_array, :end_array, :end_document]
    assert_equal(expected, events('[[]]'))

    expected = [:start_document, :start_array, :start_array, [:value, 2.1], :end_array, :end_array, :end_document]
    assert_equal(expected, events('[[ 2.10 ]]'))
  end

  def test_array
    expected = [:start_document, :start_array, :error]
    ['[}', '[,]', '[, 12]'].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_array, :start_array, :error]
    assert_equal(expected, events('[[}]'))
    ['[[}]', '[[,]]'].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_array, [:value, "test"], :error]
    ['["test"}', '["test",]', '["test" "test"]', '["test" 12]'].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_array, [:value, "test"], :end_array, :end_document]
    assert_equal(expected, events('["test"]'))

    expected = [:start_document, :start_array,
               [:value, 1],
               [:value, 2],
               [:value, nil],
               [:value, 12.1],
               [:value, "test"],
               :end_array, :end_document]
    ['[1,2, null, 12.1,"test"]'].each do |json|
      assert_equal(expected, events(json))
    end
  end

  def test_object
    expected = [:start_document, :start_object, :error]
    ['{]', '{:}'].each do |json|
      assert_equal(expected, events(json))
    end

    expected = [:start_document, :start_object, [:key, "key 1"], [:value, 12], :end_object, :end_document]
    assert_equal(expected, events('{"key 1" : 12}'))

    expected = [:start_document, :start_object,
               [:key, "key 1"], [:value, 12],
               [:key, "key 2"], [:value, "two"],
                :end_object, :end_document]
    assert_equal(expected, events('{"key 1" : 12, "key 2":"two"}'))
  end

  def test_object_key_with_no_value
    expected = [:start_document, :start_object, [:key, "key"],
                :start_array, [:value, nil], [:value, false],
               [:value, true], :end_array,
               [:key, "key 2"],
                :error]
    assert_equal(expected, events('{"key": [ null , false , true ] ,"key 2"}'))
  end

  def test_object_trailing_comma
    expected = [:start_document, :start_object, [:key, "key 1"], [:value, 12], :error]
    assert_equal(expected, events('{"key 1" : 12,}'))
  end

  def test_single_byte_utf8
    expected = [:start_document, :start_array, [:value, "test"], :end_array, :end_document]
    assert_equal(expected, events('["test"]'))
  end

  def test_full_two_byte_utf8
    expected = [:start_document, :start_array, [:value, "résumé"],
               [:value, "éé"], :end_array, :end_document]
    assert_equal(expected, events("[\"résumé\", \"é\xC3\xA9\"]"))
  end

  # Parser should throw an error when only one byte of a two byte character
  # is available. The \xC3 byte is the first byte of the é character.
  def test_partial_two_byte_utf8
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('["\xC3"]'))

    expected = [:start_document, :start_array, [:value, 'é'], :end_array, :end_document]
    assert_equal(expected, events("[\"\xC3\xA9\"]"))
  end

  def test_full_three_byte_utf8
    expected = [:start_document, :start_array, [:value, "snow\u2603man"],
               [:value, "\u2603\u2603"], :end_array, :end_document]
    assert_equal(expected, events("[\"snow\u2603man\", \"\u2603\u2603\"]"))
  end

  def test_partial_three_byte_utf8
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('["\xE2"]'))

    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('["\xE2\x98"]'))

    expected = [:start_document, :start_array, [:value, "\u2603"], :end_array, :end_document]
    assert_equal(expected, events("[\"\xE2\x98\x83\"]"))
  end

  def test_full_four_byte_utf8
    expected = [:start_document, :start_array, [:value, "\u{10102} check mark"],
                :end_array, :end_document]
    assert_equal(expected, events("[\"\u{10102} check mark\"]"))
  end

  def test_partial_four_byte_utf8
    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('["\xF0"]'))

    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('["\xF0\x90"]'))

    expected = [:start_document, :start_array, :error]
    assert_equal(expected, events('["\xF0\x90\x84"]'))

    expected = [:start_document, :start_array, [:value, "\u{10102}"], :end_array, :end_document]
    assert_equal(expected, events("[\"\xF0\x90\x84\x82\"]"))
  end

  def test_parse
    json = "[1,2,3]"
    obj = JSON::Stream::Parser.parse(json)
    assert_equal([1,2,3], obj)
  end

  def test_initializer_block
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
    assert_equal(expected, events)
  end

  private

  # Run a worst case, one character at a time, parse against the
  # JSON string and return a list of events generated by the parser.
  # A special :error event is included if the parser threw an exception.
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
