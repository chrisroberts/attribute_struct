require "attribute_struct/base"

# Helper methods for IRB interactions
class AttributeStruct
  module IrbCompat

    # @return [String] object inspection
    def inspect
      "<[#{self._klass}:#{@table.object_id}] - table: #{@table.inspect}>"
    end

    # @return [String] string of instance
    def to_s
      "<#{self._klass}:#{@table.object_id}>"
    end
  end
end
