require "attribute_struct"

class AttributeStruct
  # AttributeStruct expanded class that include the Kernel module
  # and automatically objectifies the instance
  class Augmented < ::AttributeStruct
    include ::Kernel

    # Create a new Augmented AttributeStruct instance. Passes arguments
    # and block directly to parent for initialization. Automatically
    # objectifies the instance
    #
    # @return [self]
    def initialize(*args, &block)
      super(*args, &block)
      @_objectified = true
    end

    # @return [Class]
    def _klass
      ::AttributeStruct::Augmented
    end
  end
end
