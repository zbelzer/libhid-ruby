# encoding: UTF-8
#
Gem::Specification.new do |s|
  s.name               = 'libhid-ruby'
  s.homepage           = 'http://github.com/zbelzer/libhid-ruby'
  s.summary            = 'An FFI wrapper over libhid'
  s.require_paths      = ['lib']
  s.authors            = ['Zachary Belzer', 'Michael Marion', 'Jason Norris']
  s.email              = ['zbelzer@gmail.com']
  s.version            = File.read('VERSION')
  s.platform           = Gem::Platform::RUBY
  s.files              = Dir["**/*"]

  s.add_dependency 'ffi', '>= 1.0.0'
end
