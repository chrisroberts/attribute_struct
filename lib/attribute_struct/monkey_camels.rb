require "attribute_struct/base"

class AttributeStruct
  module MonkeyCamels
    class << self
      def included(klass)
        klass.class_eval do
          include Humps

          alias_method :un_camel_to_s, :to_s
          alias_method :to_s, :camel_to_s
          alias_method :un_camel_initialize_copy, :initialize_copy
          alias_method :initialize_copy, :camel_initialize_copy
        end
      end
    end

    # Create a camel copy based on settings
    #
    # @return [String]
    def camel_initialize_copy(orig, hump = nil)
      new_val = un_camel_initialize_copy(orig)
      if (hump.nil?)
        orig._camel? ? new_val : new_val._no_hump
      else
        new_val._no_hump if hump == false
      end
    end

    # Provide string formatted based on hump setting
    #
    # @return [String]
    def camel_to_s
      val = un_camel_to_s
      _camel? ? val : val._no_hump
    end

    module Humps
      # @return [TrueClass, FalseClass] specific style requested
      def _hump_format_requested?
        if defined?(@__not_camel)
          @__not_camel != nil
        else
          false
        end
      end

      # @return [TrueClass, FalseClass] camelized
      def _camel?
        if defined?(@__not_camel)
          !@__not_camel
        else
          true
        end
      end

      # @return [self] disable camelizing
      def _no_hump
        CamelString.new(self)._no_hump
      end

      alias_method :disable_camel!, :_no_hump

      # @return [self] enable camelizing
      def _hump
        CamelString.new(self)._hump
      end

      alias_method :camel!, :_hump

      # @return [Symbol, NilClass] style of hump
      def _hump_style
        if defined?(@__hump_style)
          @__hump_style
        end
      end

      alias_method :hump_style!, :_hump_style

      # Set hump style to non-leading upcase
      #
      # @return [CamelString]
      def _bactrian
        CamelString.new(self)._bactrian
      end

      alias_method :bactrian!, :_bactrian
      alias_method :no_leading_hump!, :_bactrian

      # Set hump style to leading upcase
      #
      # @return [CamelString]
      def _dromedary
        CamelString.new(self)._dromedary
      end

      alias_method :dromedary!, :_dromedary
      alias_method :leading_hump!, :_dromedary
    end
  end

  # Force some monkeys around
  ::String.send(:include, MonkeyCamels)
  ::Symbol.send(:include, MonkeyCamels)

  # Specialized String type
  class CamelString < ::String
    def initialize(val = nil)
      super
      if (val.respond_to?(:_camel?))
        _no_hump unless val._camel?
        @__hump_style = val._hump_style
      else
        @__hump_style = nil
      end
    end

    # Set hump style to non-leading upcase
    #
    # @return [self]
    def _bactrian
      @__not_camel = false
      @__hump_style = :no_leading_hump
      self
    end
    alias_method :bactrian!, :_bactrian
    alias_method :no_leading_hump!, :_bactrian

    # Set hump style to leading upcase
    #
    # @return [self]
    def _dromedary
      @__not_camel = false
      @__hump_style = :leading_hump

      self
    end
    alias_method :dromedary!, :_dromedary
    alias_method :leading_hump!, :_dromedary

    # @return [self] disable camelizing
    def _no_hump
      @__not_camel = true
      self
    end
    alias_method :disable_camel!, :_no_hump

    # @return [self] enable camelizing
    def _hump
      @__not_camel = false
      self
    end
    alias_method :camel!, :_hump
  end
end
