require 'hashie/extensions/deep_merge'
require 'hashie/extensions/indifferent_access'

class AttributeStruct
  class AttributeHash < ::Hash
    include ::Hashie::Extensions::DeepMerge
    include ::Hashie::Extensions::IndifferentAccess

    def to_hash
      ::Hash[
        self.map do |k,v|
          [k, v.is_a?(::Hash) ? v.to_hash : v]
        end
      ]
    end
  end
end
