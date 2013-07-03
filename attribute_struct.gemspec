$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'attribute_struct/version'
Gem::Specification.new do |s|
  s.name = 'attribute_struct'
  s.version = AttributeStruct::VERSION.version
  s.summary = 'Attribute structures'
  s.author = 'Chris Roberts'
  s.email = 'chrisroberts.code@gmail.com'
  s.homepage = 'http://github.com/chrisroberts/attribute_struct'
  s.description = 'Attribute structures'
  s.require_path = 'lib'
  s.add_dependency 'hashie', '~> 2.0.5'
  s.files = Dir['**/*']
end
