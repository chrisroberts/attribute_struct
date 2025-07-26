require "attribute_struct/base"

require "attribute_struct/attribute_hash"
require "attribute_struct/augmented"
require "attribute_struct/monkey_camels"

class AttributeStruct
  class << self

    # @return [Hash] valid styles and mapped value
    VALID_CAMEL_STYLES = {
      :bactrian => :no_leading,
      :no_leading_hump => :no_leading,
      :no_leading => :no_leading,
      :dromedary => :leading,
      :leading_hump => :leading,
      :leading => :leading,
    }

    # @return [Truthy, Falsey] global flag for camel keys
    attr_reader :camel_keys
    # @return [Symbol] camel key style
    attr_reader :camel_style

    # Automatically converts keys to camel case
    #
    # @param val [TrueClass, FalseClass]
    # @return [TrueClass, FalseClass]
    def camel_keys=(val)
      load_the_camels if val
      @camel_keys = !!val
    end

    # Set default style of camel keys
    #
    # @param val [Symbol]
    # @return [Symbol]
    def camel_style=(val)
      @camel_style = validate_camel_style(val)
    end

    # Validate requested camel style and return mapped value used
    # internally
    #
    # @param style [Symbol]
    # @return [Symbol]
    # @raises [ArgumentError]
    def validate_camel_style(style)
      if (VALID_CAMEL_STYLES.has_key?(style))
        VALID_CAMEL_STYLES[style]
      else
        valid_types = VALID_CAMEL_STYLES.keys(&:inspect).join(", ")
        raise ArgumentError.new "Unsupported camel style provided " \
                                "`#{style.inspect}`! (Allowed: #{valid_types})"
      end
    end

    # Loads helpers for camel casing
    def load_the_camels
      unless defined?(@camels_loaded)
        require "attribute_struct/monkey_camels"
        @camels_loaded = true
      end
    end

    # @return [AttributeStruct::AttributeHash]
    def hashish
      ::AttributeStruct::AttributeHash
    end

    # Create AttributeStruct instance and dump the resulting hash
    def build(&block)
      raise ArgumentError.new "Block required for build!" unless block
      new(&block)._dump
    end

    # Enable IRB compatibility mode
    #
    # @return [TrueClass]
    # @note this will add methods required for working within IRB
    def irb_compat!
      self.send(:include, IrbCompat)
      true
    end
  end

  # value used to identify unset value
  UNSET_VALUE = :__unset__

  # Specialized array for collapsing values
  class CollapseArray < ::Array; end

  # @return [Truthy, Falsey] current camelizing setting
  attr_reader :_camel_keys
  alias_method :camel_keys!, :_camel_keys
  # @return [Symbol] current camel style
  attr_reader :_camel_style
  alias_method :camel_style!, :_camel_style
  # @return [AtributeStruct::AttributeHash, Mash] holding space for state
  attr_reader :_arg_state
  alias_method :arg_state!, :_arg_state

  # Create new instance
  #
  # @param init_hash [Hash] hash to initialize struct
  # @yield block to execute within struct context
  def initialize(init_hash = nil, &block)
    @_camel_keys = _klass.camel_keys
    @_camel_keys_set = nil
    @_parent = nil
    @_arg_state = __hashish.new
    @_kernelified = false
    @_objectified = false
    @table = __hashish.new
    if (init_hash)
      _load(init_hash)
    end
    if (block)
      self.instance_exec(&block)
    end
  end

  # Execute block within current context
  #
  # @yield block to execute
  # @return [Object]
  def _build(&block)
    self.instance_exec(&block)
  end

  alias_method :build!, :_build

  # Set state into current context
  #
  # @param args [Hashish] hashish type holding data for context
  # @return [Hashish]
  def _set_state(args = {})
    _arg_state.merge!(args)
  end

  alias_method :set_state!, :_set_state

  # Value of requested state
  #
  # @param key [Symbol, String]
  # @param traverse [TrueClass, FalseClass] traverse towards root for matching key
  # @return [Object, NilClass]
  def _state(key, traverse = true)
    if (_arg_state.has_key?(key))
      _arg_state[key]
    else
      if (traverse && _parent)
        _parent._state(key)
      end
    end
  end

  alias_method :state!, :_state

  # Enable/disable camel keys
  #
  # @param val [TrueClass, FalseClass]
  # @return [TrueClass, FalseClass]
  def _camel_keys=(val)
    _klass.load_the_camels if val
    @_camel_keys = !!val
  end

  # Set style of camel keys
  #
  # @param val [Symbol]
  # @return [Symbol]
  def _camel_style=(val)
    @_camel_style = ::AttributeStruct.validate_camel_style(val)
  end

  # Enable/disable root constant lookups
  #
  # @param enable [TrueClass, FalseClass]
  # @return [TrueClass, FalseClass]
  def _objectify(enable = true)
    @_objectified = !!enable
  end

  alias_method :objectify!, :_objectify

  # @return [TrueClass, FalseClass]
  def objectified?
    @_objectified
  end

  # Direct data access
  #
  # @param key [String, Symbol]
  # @return [Object]
  def [](key)
    _data[_process_key(key)]
  end

  # Directly set value into struct. Useful when the key
  # is not valid ruby syntax for a method
  #
  # @param key [String, Symbol]
  # @param val [Object]
  # @yield block to execute within context
  # @return [Object]
  def _set(key, val = UNSET_VALUE, &block)
    if (val != UNSET_VALUE)
      self.method_missing(key, val, &block)
    else
      self.method_missing(key, &block)
    end
  end

  alias_method :set!, :_set

  # Provides struct DSL behavior
  #
  # @param sym [Symbol, String] method name
  # @param args [Object] argument list
  # @yield provided block
  # @return [Object] existing value or newly set value
  # @note Dragons and unicorns all over in here
  def method_missing(_sym, *_args, &_block)
    if (objectified? && _args.empty? && _block.nil?)
      _o_lookup = _objectified_constant_lookup(_sym)
      return _o_lookup if _o_lookup
    end
    if (_sym.is_a?(::String) || _sym.is_a?(::Symbol))
      if ((_s = _sym.to_s).end_with?("="))
        _s.slice!(-1, _s.length)
        _sym = _s
      end
      _sym = _process_key(_sym)
    end
    if (!_args.empty? || _block)
      if (_args.empty? && _block)
        _base = @table.fetch(_sym, UNSET_VALUE)
        if (_state(:value_collapse) && !_base.is_a?(self.class!))
          _orig = _base
          _base = _klass_new
        else
          unless (_base.is_a?(self.class!))
            _base = _klass_new
          end
        end
        @table[_sym] = _base
        if (_block.arity == 0)
          _base.instance_exec(&_block)
        else
          _base.instance_exec(_base, &_block)
        end
        if (_orig.is_a?(::NilClass))
          @table[_sym] = _base
        else
          if (_orig == UNSET_VALUE)
            @table[_sym] = _base
          else
            unless (_orig.is_a?(CollapseArray))
              _orig = CollapseArray.new.push(_orig)
            end
            _orig << _base
            @table[_sym] = _orig
          end
        end
      elsif (!_args.empty? && _block)
        _result = _leaf = _base = @table.fetch(_sym, _klass_new)
        @table[_sym] = _result

        _args.flatten.each do |_arg|
          _leaf = _base[_arg]
          unless (_leaf.is_a?(_klass))
            _leaf = _klass_new
            _base._set(_arg, _leaf)
            _base = _leaf
          end
        end
        if (!_leaf.nil? && _state(:value_collapse))
          _orig = _leaf
          _leaf = _orig.parent._klass_new
        end
        _block.arity == 0 ? _leaf._build(&_block) : _leaf._build(_leaf, &_block)
        if (_orig)
          unless (_orig.is_a?(CollapseArray))
            _orig = CollapseArray.new.push(_orig)
          end
          _orig << _leaf
        else
          _orig = _leaf
        end
      else
        if (_args.size > 1 && _args.all? { |_i| _i.is_a?(::String) || _i.is_a?(::Symbol) } && !_state(:value_collapse))
          @table[_sym] = _klass_new unless @table[_sym].is_a?(_klass)
          _endpoint = _args.inject(@table[_sym]) do |_memo, _k|
            unless (_memo[_k].is_a?(_klass))
              _memo._set(_k, _klass_new)
            end
            _memo[_k]
          end
          return _endpoint # custom break out
        else
          if (_args.size > 1)
            _val = _args.map do |_v|
              if (_v.is_a?(::Hash) && _state(:hash_load_struct))
                _val = _klass_new
                _val._load(_v)
              else
                _v
              end
            end
          else
            if (_args.first.is_a?(::Hash) && _state(:hash_load_struct))
              _val = _klass_new
              _val._load(_args.first)
            else
              _val = _args.first
            end
          end
          if (_state(:value_collapse) && !(_leaf = @table[_sym]).nil?)
            unless (_leaf.is_a?(CollapseArray))
              _leaf = CollapseArray.new.push(_leaf)
            end
            _leaf << _val
            @table[_sym] = _leaf
          else
            @table[_sym] = _val
          end
        end
      end
    end
    @table[_sym] = _klass_new if @table[_sym].nil? && !@table[_sym].is_a?(_klass)
    @table[_sym]
  end

  # @return [TrueClass, FalseClass] struct is nil (empty data)
  def nil?
    _data.empty?
  end

  # @return [TrueClass, FalseClass] struct is present (not empty)
  def present?
    !nil?
  end

  # Determine if self is a class
  #
  # @param klass [Class]
  # @return [TrueClass, FalseClass]
  def is_a?(klass)
    (_klass.ancestors + [::AttributeStruct]).include?(klass)
  end

  alias_method :kind_of?, :is_a?

  # Check if key exists within struct
  #
  # @param key [String, Symbol]
  # @return [TrueClass, FalseClass]
  def key?(key)
    self._keys.include?(_process_key(key))
  end

  alias_method :has_key?, :key?

  # @return [Array<String,Symbol>] keys within struct
  def _keys
    _data.keys
  end

  alias_method :keys!, :_keys

  # @return [AttributeStruct::AttributeHash, Mash] underlying struct data
  def _data
    @table
  end

  alias_method :data!, :_data

  # Delete entry from struct
  #
  # @param key [String, Symbol]
  # @return [Object] value of entry
  def _delete(key)
    _data.delete(_process_key(key))
  end

  alias_method :delete!, :_delete

  # Process and unpack items for dumping within deeply nested
  # enumerable types
  #
  # @param item [Object]
  # @return [Object]
  def _dump_unpacker(item)
    if (item.is_a?(::Enumerable))
      if (item.respond_to?(:keys))
        item.class[
          *item.map do |entry|
            _dump_unpacker(entry)
          end.flatten(1)
        ]
      else
        item.class[
          *item.map do |entry|
            _dump_unpacker(entry)
          end
        ]
      end
    elsif (item.is_a?(::AttributeStruct))
      item.nil? ? UNSET_VALUE : item._dump
    else
      item
    end
  end

  # @return [AttributeStruct::AttributeHash, Mash] dump struct to hashish
  def _dump
    processed = @table.keys.map do |key|
      value = @table[key]
      val = _dump_unpacker(value)
      [_dump_unpacker(key), val] unless val == UNSET_VALUE
    end.compact
    __hashish[*processed.flatten(1)]
  end

  alias_method :dump!, :_dump

  # Clear current struct data and replace
  #
  # @param hashish [Hash] hashish type instance
  # @return [self]
  def _load(hashish)
    @table.clear
    if (_root._camel_keys_action == :auto_discovery)
      starts = hashish.keys.map { |k| k[0, 1] }
      unless (starts.detect { |k| k =~ /[A-Z]/ })
        _camel_keys_set(:auto_disable)
      else
        _camel_keys_set(:auto_enable) unless _parent.nil?
      end
    end
    hashish.each do |key, value|
      if (value.is_a?(::Enumerable))
        flat = value.map do |v|
          v.is_a?(::Hash) ? _klass_new(v) : v
        end
        value = value.is_a?(::Hash) ? __hashish[*flat.flatten(1)] : flat
      end
      if (value.is_a?(::Hash))
        self._set(key)._load(value)
      else
        self._set(key, value)
      end
    end
    self
  end

  alias_method :load!, :_load

  # Perform deep merge
  #
  # @param overlay [AttributeStruct]
  # @return [AttributeStruct] newly merged instance
  def _merge(overlay)
    source = _deep_copy
    dest = overlay._deep_copy
    result = source.deep_merge(dest)
    _klass_new(result)
  end

  # Perform deep merge in place
  #
  # @param overlay [AttributeStruct]
  # @return [self]
  def _merge!(overlay)
    result = _merge(overlay)._dump
    _load(result)
    self
  end

  # @return [Class] hashish type available
  def __hashish
    ::AttributeStruct::AttributeHash
  end

  # Provide dup of instance
  #
  # @param v [Object]
  # @return [Object] duped instance
  # @note if Symbol provided, String is returned
  def _do_dup(v)
    begin
      v.dup
    rescue
      v.is_a?(::Symbol) ? v.to_s : v
    end
  end

  # Create a "deep" copy
  #
  # @param thing [Object] struct to copy. defaults to self
  # @return [Object] new instance
  def _deep_copy(thing = nil)
    thing ||= _dump
    if (thing.is_a?(::Enumerable))
      val = thing.map { |v| v.is_a?(::Enumerable) ? _deep_copy(v) : _do_dup(v) }
    else
      val = _do_dup(thing)
    end
    if (thing.is_a?(::Hash))
      val = __hashish[*val.flatten(1)]
    end
    val
  end

  # Provide expected key format based on context
  #
  # @param key [String, Symbol]
  # @param args [Object] argument list (:force will force processing)
  # @return [String, Symbol]
  def _process_key(key, *args)
    if (key.is_a?(::String) || key.is_a?(::Symbol))
      key = CamelString.new(key.to_s) unless key.is_a?(CamelString)
      if (_camel_keys && _camel_keys_action && !key._hump_format_requested?)
        case _camel_keys_action
        when :auto_disable
          key._no_hump
        when :auto_enable
          key._hump
        end
      end
      if (_camel_keys && (key._camel? || args.include?(:force)))
        camel_args = [key]
        if (key._hump_style || _camel_style == :no_leading)
          unless (key._hump_style == :leading_hump)
            camel_args << false
          end
        end
        ::Bogo::Utility.camel(*camel_args)
      else
        key
      end
    else
      key
    end
  end

  alias_method :process_key!, :_process_key

  # @return [Class] this class
  def _klass
    ::AttributeStruct
  end

  # @return [Class] this clas
  def klass!
    _klass
  end

  alias_method :class!, :klass!
  alias_method :class, :klass!

  # @return [AttributeStruct] new struct instance
  # @note will set self as parent and propogate camelizing status
  def _klass_new(*args, &block)
    n = _klass.new(*args, &block)
    unless (_camel_keys_action == :auto_discovery)
      n._camel_keys_set(_camel_keys_action)
    end
    n._camel_keys = _camel_keys
    n._camel_style = _camel_style if _camel_style
    n._objectify if objectified?
    n._kernelify if kernelified?
    n._parent(self)
    n
  end

  # Set custom rule for processed keys at this context level
  #
  # @param v [Symbol] :auto_disable or :auto_enable
  # @return [Symbol]
  def _camel_keys_set(v)
    @_camel_keys_set = v
  end

  alias_method :camel_keys_set!, :_camel_keys_set

  # @return [Symbol, NilClass] :auto_disable or :auto_enable
  def _camel_keys_action
    @_camel_keys_set
  end

  # @return [AttributeStruct, NilClass] parent of this struct
  def _parent(obj = nil)
    @_parent = obj if obj
    @_parent
  end

  alias_method :parent!, :_parent

  # @return [AttributeStruct, NilClass] root of the struct or nil if self is root
  def _root
    r = self
    until (r._parent == nil)
      r = r._parent
    end
    r
  end

  alias_method :root!, :_root

  # Create an Array and evaluate discovered AttributeStructs
  #
  # @param args [Object] array contents
  # @return [Array]
  def _array(*args)
    args.map do |maybe_block|
      if (maybe_block.is_a?(::Proc))
        klass = _klass_new
        if (maybe_block.arity > 0)
          klass.instance_exec(klass, &maybe_block)
        else
          klass.instance_exec(&maybe_block)
        end
        klass
      else
        maybe_block
      end
    end
  end

  alias_method :array!, :_array

  # Instance responds to method name
  #
  # @param name [Symbol, String]
  # @return [TrueClass, FalseClass]
  def respond_to?(name)
    _klass.instance_methods.map(&:to_sym).include?(name.to_sym)
  end

  # Lookup constant in root namespace
  #
  # @param konst [Symbol, String]
  # @return [Object, NilClass]
  def _objectified_constant_lookup(konst)
    if (konst.to_s[0].match(/[A-Z]/) && ::Object.const_defined?(konst))
      ::Object.const_get(konst)
    end
  end

  # Inject Kernel methods
  #
  # @return [TrueClass]
  def _kernelify
    unless (kernelified?)
      @_kernelified = true
      (::Kernel.public_instance_methods + ::Kernel.private_instance_methods).each do |m_name|
        self.instance_eval("def #{m_name}(*a, &b); ::Kernel.instance_method(:#{m_name}).bind(self).curry.call(*a, &b); end")
      end
    end
    true
  end

  alias_method :kernelify!, :_kernelify

  # @return [TrueClass, FalseClass] Kernel methods have been injected
  def kernelified?
    !!@_kernelified
  end

  # @return [Numeric]
  def hash
    ::Kernel.instance_method(:hash).bind(self).curry.call
  end

  # @return [AttributeStruct] clone of current instance
  def _clone(_new_parent = nil)
    _cloned_inst = _klass_new
    _cloned_inst._data.replace __hashish[
                                 @table.map { |_key, _value|
                                   if (_key.is_a?(::AttributeStruct))
                                     _key = _key._clone
                                   else
                                     _key = _do_dup(_key)
                                   end
                                   if (_value.is_a?(::AttributeStruct))
                                     _value = _value._clone
                                   else
                                     _value = _do_dup(_value)
                                   end
                                   [_key, _value]
                                 }
                               ]
    _cloned_inst._parent(_new_parent) if _new_parent
    _cloned_inst
  end

  alias_method :clone!, :_clone
end

require "attribute_struct/attribute_hash"
require "attribute_struct/version"
