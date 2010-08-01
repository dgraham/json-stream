# encoding: UTF-8

require 'json/stream'
require 'test/unit'

class BufferTest < Test::Unit::TestCase
  def setup
    @buf = JSON::Stream::Buffer.new
  end

  def test_single_byte_chars
    assert_equal("", @buf << "")
    assert_equal("abc", @buf << "abc")
    assert_equal("\u0000abc", @buf << "\u0000abc")
  end

  def test_valid_two_byte_chars
    assert_equal("abcé", @buf << "abcé")
    assert_equal("a", @buf << "a\xC3")
    assert_equal("é", @buf << "\xA9")
    assert_equal("", @buf << "\xC3")
    assert_equal("é", @buf << "\xA9")
    assert_equal("é", @buf << "\xC3\xA9")
  end

  def test_valid_three_byte_chars
    assert_equal("abcé\u2603", @buf << "abcé\u2603")
    assert_equal("a", @buf << "a\xE2")
    assert_equal("", @buf << "\x98")
    assert_equal("\u2603", @buf << "\x83")
  end

  def test_valid_four_byte_chars
    assert_equal("abcé\u2603\u{10102}é", @buf << "abcé\u2603\u{10102}é")
    assert_equal("a", @buf << "a\xF0")
    assert_equal("", @buf << "\x90")
    assert_equal("", @buf << "\x84")
    assert_equal("\u{10102}", @buf << "\x82")
  end

  def test_invalid_two_byte_start_chars
    assert_raise(JSON::Stream::ParserError) { @buf << "\xC3\xC3" }
  end

  def test_invalid_three_byte_start_chars
    assert_raise(JSON::Stream::ParserError) { @buf << "\xE2\xE2" }
  end

  def test_invalid_four_byte_start_chars
    assert_raise(JSON::Stream::ParserError) { @buf << "\xF0\xF0" }
  end

  def test_two_byte_start_with_single_byte_continuation_char
    assert_raise(JSON::Stream::ParserError) { @buf << "\xC3\u0000" }
  end

  def test_three_byte_start_with_single_byte_continuation_char
    assert_raise(JSON::Stream::ParserError) { @buf << "\xE2\u0010" }
  end

  def test_four_byte_start_with_single_byte_continuation_char
    assert_raise(JSON::Stream::ParserError) { @buf << "\xF0a" }
  end

  def test_invalid_continuation_char
    assert_raise(JSON::Stream::ParserError) { @buf << "\xA9" }
  end

  def test_overlong_form
    assert_raise(JSON::Stream::ParserError) { @buf << "\xC0\x80" }
  end
end
