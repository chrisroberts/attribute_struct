require 'attribute_struct/attribute_struct'

class AttributeStruct
  # Custom version container
  class Version < ::Gem::Version
  end
  # Current library version
  VERSION = Version.new('0.2.0')
end
