require 'hashie/extensions/deep_merge'
require 'hashie/extensions/indifferent_access'

class AttributeStruct
  class AttributeHash < ::Hash
    include Hashie::Extensions::DeepMerge
    include Hashie::Extensions::IndifferentAccess
  end
end
