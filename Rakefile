require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLOBBER.include('pkg')

directory 'pkg'

desc 'Build distributable packages'
task :build => [:pkg] do
  system 'gem build json-stream.gemspec && mv json-*.gem pkg/'
end

Rake::TestTask.new(:test) do |test|
  test.libs << 'spec'
  test.pattern = 'spec/**/*_spec.rb'
  test.warning = true
end

task :default => [:clobber, :test, :build]
