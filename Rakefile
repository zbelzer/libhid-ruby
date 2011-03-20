require 'rubygems'
require 'rake'

desc 'Builds the gem'
task :build do
  system "gem build libhid-ruby.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  system "gem install libhid-ruby-#{File.read('VERSION')}"
end
