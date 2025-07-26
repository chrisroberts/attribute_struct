$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + "/lib/"
require "attribute_struct/version"
Gem::Specification.new do |s|
  s.name = "attribute_struct"
  s.version = AttributeStruct::VERSION.version
  s.summary = "Attribute structures"
  s.author = "Chris Roberts"
  s.license = "Apache 2.0"
  s.email = "chrisroberts.code@gmail.com"
  s.homepage = "http://github.com/chrisroberts/attribute_struct"
  s.description = "Attribute structures"
  s.require_path = "lib"
  s.add_runtime_dependency "bogo", ">= 0.1.31", "< 0.3.0"
  s.add_runtime_dependency "logger"
  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "rake", "~> 13"
  s.add_development_dependency "minitest"
  s.files = Dir["lib/**/*"] + %w(attribute_struct.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
