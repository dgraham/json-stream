# encoding: UTF-8

require 'json/stream'
require 'minitest/autorun'

describe JSON::Stream::Buffer do
  subject { JSON::Stream::Buffer.new }

  it 'accepts single byte characters' do
    assert_equal("", subject << "")
    assert_equal("abc", subject << "abc")
    assert_equal("\u0000abc", subject << "\u0000abc")
  end

  # The é character can be a single codepoint \u00e9 or two codepoints
  # \u0065\u0301. The first is encoded in 2 bytes, the second in 3 bytes.
  # The json and yajl-ruby gems and CouchDB do not normalize unicode text
  # so neither will we. Although, a good way to normalize is by calling
  # ActiveSupport::Multibyte::Chars.new("é").normalize(:c).
  it 'accepts combined characters' do
    assert_equal("\u0065\u0301", subject << "\u0065\u0301")
    assert_equal(3, (subject << "\u0065\u0301").bytesize)
    assert_equal(2, (subject << "\u0065\u0301").size)

    assert_equal("\u00e9", subject << "\u00e9")
    assert_equal(2, (subject << "\u00e9").bytesize)
    assert_equal(1, (subject << "\u00e9").size)
  end

  it 'accepts valid two byte characters' do
    assert_equal("abcé", subject << "abcé")
    assert_equal("a", subject << "a\xC3")
    assert_equal("é", subject << "\xA9")
    assert_equal("", subject << "\xC3")
    assert_equal("é", subject << "\xA9")
    assert_equal("é", subject << "\xC3\xA9")
  end

  it 'accepts valid three byte characters' do
    assert_equal("abcé\u2603", subject << "abcé\u2603")
    assert_equal("a", subject << "a\xE2")
    assert_equal("", subject << "\x98")
    assert_equal("\u2603", subject << "\x83")
  end

  it 'accepts valid four byte characters' do
    assert_equal("abcé\u2603\u{10102}é", subject << "abcé\u2603\u{10102}é")
    assert_equal("a", subject << "a\xF0")
    assert_equal("", subject << "\x90")
    assert_equal("", subject << "\x84")
    assert_equal("\u{10102}", subject << "\x82")
  end

  it 'rejects invalid two byte start characters' do
    assert_raises(JSON::Stream::ParserError) { subject << "\xC3\xC3" }
  end

  it 'rejects invalid three byte start characters' do
    assert_raises(JSON::Stream::ParserError) { subject << "\xE2\xE2" }
  end

  it 'rejects invalid four byte start characters' do
    assert_raises(JSON::Stream::ParserError) { subject << "\xF0\xF0" }
  end

  it 'rejects a two byte start with single byte continuation character' do
    assert_raises(JSON::Stream::ParserError) { subject << "\xC3\u0000" }
  end

  it 'rejects a three byte start with single byte continuation character' do
    assert_raises(JSON::Stream::ParserError) { subject << "\xE2\u0010" }
  end

  it 'rejects a four byte start with single byte continuation character' do
    assert_raises(JSON::Stream::ParserError) { subject << "\xF0a" }
  end

  it 'rejects an invalid continuation character' do
    assert_raises(JSON::Stream::ParserError) { subject << "\xA9" }
  end

  it 'rejects an overlong form' do
    assert_raises(JSON::Stream::ParserError) { subject << "\xC0\x80" }
  end
end
