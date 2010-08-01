require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/testtask'
require File.join(File.expand_path(File.dirname(__FILE__)), 'lib', 'json', 'stream')

spec = Gem::Specification.new do |s| 
  s.name = "json-stream"
  s.version = JSON::Stream::VERSION
  s.date = Time.now.strftime("%Y-%m-%d")
  s.summary = "A streaming JSON parser that generates SAX-like events."
  s.description = "A finite state machine based JSON parser that generates events
for each state change. This allows us to stream both the JSON document into
memory and the parsed object graph out of memory to some other process.  This
is much like an XML SAX parser that generates events during parsing.  There is
no requirement for the document nor the object graph to be fully buffered in
memory.  This is best suited for huge JSON documents that won't fit in memory.
For example, streaming and processing large map/reduce views from Apache CouchDB."
  s.email = "david.malcom.graham@gmail.com"
  s.homepage = "http://github.com/dgraham/json-stream"
  s.authors = ["David Graham"]
  s.files = FileList['LICENSE', 'README', 'Rakefile', "{lib}/**/*"].to_a
  s.require_path = "lib"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.required_ruby_version = '>= 1.9.1'
end
 
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true 
end 

Rake::TestTask.new(:test) do |test|
  test.pattern = 'test/**/*_test.rb'
  test.warning = true
end

task :default => [:clobber, :test, :gem]
