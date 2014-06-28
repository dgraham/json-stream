# encoding: UTF-8

require 'json/stream'
require 'minitest/autorun'

describe JSON::Stream::Builder do
  subject { JSON::Stream::Builder.new(JSON::Stream::Parser.new) }

  it 'builds a false value' do
    assert_nil subject.result
    subject.start_document
    subject.value(false)
    assert_nil subject.result
    subject.end_document
    assert_equal false, subject.result
  end

  it 'builds a string value' do
    assert_nil subject.result
    subject.start_document
    subject.value("test")
    assert_nil subject.result
    subject.end_document
    assert_equal "test", subject.result
  end

  it 'builds an empty array' do
    assert_nil subject.result
    subject.start_document
    subject.start_array
    subject.end_array
    assert_nil subject.result
    subject.end_document
    assert_equal [], subject.result
  end

  it 'builds an array of numbers' do
    subject.start_document
    subject.start_array
    subject.value(1)
    subject.value(2)
    subject.value(3)
    subject.end_array
    subject.end_document
    assert_equal [1, 2, 3], subject.result
  end

  it 'builds nested empty arrays' do
    subject.start_document
    subject.start_array
    subject.start_array
    subject.end_array
    subject.end_array
    subject.end_document
    assert_equal [[]], subject.result
  end

  it 'builds nested arrays of numbers' do
    subject.start_document
    subject.start_array
    subject.value(1)
    subject.start_array
    subject.value(2)
    subject.end_array
    subject.value(3)
    subject.end_array
    subject.end_document
    assert_equal [1, [2], 3], subject.result
  end

  it 'builds an empty object' do
    subject.start_document
    subject.start_object
    subject.end_object
    subject.end_document
    assert_equal({}, subject.result)
  end

  it 'builds a complex object' do
    subject.start_document
    subject.start_object
    subject.key("k1")
    subject.value(1)
    subject.key("k2")
    subject.value(nil)
    subject.key("k3")
    subject.value(true)
    subject.key("k4")
    subject.value(false)
    subject.key("k5")
    subject.value("string value")
    subject.end_object
    subject.end_document
    expected = {
      "k1" => 1,
      "k2" => nil,
      "k3" => true,
      "k4" => false,
      "k5" => "string value"
    }
    assert_equal expected, subject.result
  end

  it 'builds a nested object' do
    subject.start_document
    subject.start_object
    subject.key("k1")
    subject.value(1)

    subject.key("k2")
    subject.start_object
    subject.end_object

    subject.key("k3")
    subject.start_object
      subject.key("sub1")
      subject.start_array
        subject.value(12)
      subject.end_array
    subject.end_object

    subject.key("k4")
    subject.start_array
      subject.value(1)
      subject.start_object
        subject.key("sub2")
        subject.start_array
        subject.value(nil)
        subject.end_array
      subject.end_object
    subject.end_array

    subject.key("k5")
    subject.value("string value")
    subject.end_object
    subject.end_document
    expected = {
      "k1" => 1,
      "k2" => {},
      "k3" => {"sub1" => [12]},
      "k4" => [1, {"sub2" => [nil]}],
      "k5" => "string value"
    }
    assert_equal expected, subject.result
  end
end
