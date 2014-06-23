# encoding: UTF-8

require 'json/stream'
require 'minitest/autorun'

class BuilderTest < MiniTest::Unit::TestCase
  def setup
    @b = JSON::Stream::Builder.new(JSON::Stream::Parser.new)
  end

  def test_empty_array
    assert_nil(@b.result)
    @b.start_document
    @b.start_array
    @b.end_array
    assert_nil(@b.result)
    @b.end_document
    assert_equal([], @b.result)
  end

  def test_number_array
    @b.start_document
    @b.start_array
    @b.value(1)
    @b.value(2)
    @b.value(3)
    @b.end_array
    @b.end_document
    assert_equal([1,2,3], @b.result)
  end

  def test_nested_empty_arrays
    @b.start_document
    @b.start_array
    @b.start_array
    @b.end_array
    @b.end_array
    @b.end_document
    assert_equal([[]], @b.result)
  end

  def test_nested_arrays
    @b.start_document
    @b.start_array
    @b.value(1)
    @b.start_array
    @b.value(2)
    @b.end_array
    @b.value(3)
    @b.end_array
    @b.end_document
    assert_equal([1,[2],3], @b.result)
  end

  def test_empty_object
    @b.start_document
    @b.start_object
    @b.end_object
    @b.end_document
    assert_equal({}, @b.result)
  end

  def test_object
    @b.start_document
    @b.start_object
    @b.key("k1")
    @b.value(1)
    @b.key("k2")
    @b.value(nil)
    @b.key("k3")
    @b.value(true)
    @b.key("k4")
    @b.value(false)
    @b.key("k5")
    @b.value("string value")
    @b.end_object
    @b.end_document
    expected = {"k1" => 1, "k2" => nil, "k3" => true,
                "k4" => false, "k5" => "string value"}
    assert_equal(expected, @b.result)
  end

  def test_nested_object
    @b.start_document
    @b.start_object
    @b.key("k1")
    @b.value(1)

    @b.key("k2")
    @b.start_object
    @b.end_object

    @b.key("k3")
    @b.start_object
      @b.key("sub1")
      @b.start_array
        @b.value(12)
      @b.end_array
    @b.end_object

    @b.key("k4")
    @b.start_array
      @b.value(1)
      @b.start_object
        @b.key("sub2")
        @b.start_array
        @b.value(nil)
        @b.end_array
      @b.end_object
    @b.end_array

    @b.key("k5")
    @b.value("string value")
    @b.end_object
    @b.end_document
    expected = {"k1"=>1,
                "k2"=>{},
                "k3"=>{"sub1"=>[12]},
                "k4"=>[1, {"sub2"=>[nil]}],
                "k5"=>"string value"}
    assert_equal(expected, @b.result)
  end
end
