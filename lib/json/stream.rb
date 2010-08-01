# encoding: UTF-8

$:.unshift File.dirname(__FILE__) unless
  $:.include?(File.dirname(__FILE__))

require 'stringio'
require 'stream/buffer'
require 'stream/builder'
require 'stream/parser'

module JSON
  module Stream
    VERSION = "0.1.0"
  end
end
