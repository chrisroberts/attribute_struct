class AttributeStruct < BasicObject

  class << self

    # Global flag for camel cased keys
    attr_reader :camel_keys
    # Force tooling from Chef
    attr_accessor :force_chef

    # val:: bool
    # Automatically converts keys to camel case
    def camel_keys=(val)
      load_the_camels if val
      @camel_keys = !!val
    end

    # Loads helpers for camel casing
    def load_the_camels
      unless(@camels_loaded)
        require 'attribute_struct/monkey_camels'
        @camels_loaded = true
      end
    end

    # Determines what hash library to load based on availability
    def load_the_hash
      unless(@hash_loaded)
        if(defined?(Chef) || force_chef)
          require 'chef/mash'
          require 'chef/mixin/deep_merge'
          @hash_loaded = :chef
        else
          require 'attribute_struct/attribute_hash'
          @hash_loaded = :attribute_hash
        end
      end
    end

    def hashish
      load_the_hash
      @hash_loaded == :chef ? ::Mash : ::AttributeStruct::AttributeHash
    end

    # Create AttributeStruct instance and dump the resulting hash
    def build(&block)
      raise ArgumentError.new 'Block required for build!' unless block
      new(&block)._dump
    end

  end

  # Flag for camel cased keys
  attr_reader :_camel_keys, :_arg_state

  def initialize(*args, &block)
    _klass.load_the_hash
    @_camel_keys = _klass.camel_keys
    @_arg_state = self.class.hashish.new
    @table = __hashish.new
    unless(args.empty?)
      if(args.size == 1 && args.first.is_a?(::Hash))
        _load(args.first)
      end
    end
    if(block)
      self.instance_exec(&block)
    end
  end

  # Helper method. Execute given block within instance
  def _build(&block)
    self.instance_exec(&block)
  end

  # args:: Argument hash
  # Set Hash into argument state
  def _set_state(args={})
    _arg_state.merge!(args)
  end

  # key:: key for arg state lookup
  # traverse:: search towards root for matching key
  # Return value of key if found
  def _state(key, traverse=true)
    if(_arg_state.keys.include?(key))
      _arg_state[key]
    else
      if(traverse && _parent)
        _parent._state(key)
      end
    end
  end

  # val:: bool
  # Turn camel cased keys on/off
  def _camel_keys=(val)
    _klass.load_the_camels if val
    @_camel_keys = !!val
  end

  # key:: Object
  # Access data directly
  def [](key)
    _data[_process_key(key)]
  end

  # key:: Object
  # val:: Object
  # Directly set val into struct. Useful when key is not valid syntax
  # for a ruby method
  def _set(key, val=nil, &block)
    if(val)
      self.method_missing(key, val, &block)
    else
      self.method_missing(key, &block)
    end
  end

  # Dragons and unicorns all over in here
  def method_missing(sym, *args, &block)
    if((s = sym.to_s).end_with?('='))
      s.slice!(-1, s.length)
      sym = s
    end
    sym = _process_key(sym)
    if(!args.empty? || block)
      if(args.empty? && block)
        if(_state(:value_collapse))
          orig = @table.fetch(sym, :__unset__)
        end
        base = _klass_new
        if(block.arity == 0)
          base.instance_exec(&block)
        else
          base.instance_exec(base, &block)
        end
        if(orig.is_a?(::NilClass))
          @table[sym] = base
        else
          if(orig == :__unset__)
            @table[sym] = base
          else
            orig = [orig] unless orig.is_a?(::Array)
            orig << base
            @table[sym] = orig
          end
        end
      elsif(!args.empty? && block)
        base = @table[sym]
        base = _klass_new unless base.is_a?(_klass)
        leaf = base
        key = sym
        args.each do |arg|
          leaf = base[arg]
          key = arg
          unless(leaf.is_a?(_klass))
            leaf = _klass_new
            base._set(arg, leaf)
            base = leaf
          end
        end
        if(!leaf.nil? && _state(:value_collapse))
          orig = leaf
          leaf = orig.parent._klass_new
        end
        if(block.arity == 0)
          leaf.instance_exec(&block)
        else
          leaf.instance_exec(leaf, &block)
        end
        if(orig)
          orig = [orig] unless orig.is_a?(::Array)
          orig << leaf
        else
          orig = leaf
        end
        @table[sym] = orig
      else
        if(args.size > 1)
          @table[sym] = _klass_new unless @table[sym].is_a?(_klass)
          endpoint = args.inject(@table[sym]) do |memo, k|
            unless(memo[k].is_a?(_klass))
              memo._set(k, _klass_new)
            end
            memo[k]
          end
          return endpoint # custom break out
        else
          if(_state(:value_collapse) && !(leaf = @table[sym]).nil?)
            leaf = [leaf] unless leaf.is_a?(::Array)
            leaf << args.first
            @table[sym] = leaf
          else
            @table[sym] = args.first
          end
        end
      end
    end
    @table[sym] = _klass_new if @table[sym].nil? && !@table[sym].is_a?(_klass)
    @table[sym]
  end

  # Returns if this struct is considered nil (empty data)
  def nil?
    _data.empty?
  end

  # klass:: Class
  # Returns if this struct is a klass
  def is_a?(klass)
    klass.ancestors.include?(_klass)
  end
  alias_method :kind_of?, :is_a?

  # Returns current keys within struct
  def _keys
    _data.keys
  end

  # Returns underlying data hash
  def _data
    @table
  end

  # key:: Object
  # Delete entry in struct with key
  def _delete(key)
    _data.delete(_process_key(key))
  end

  # Dumps the current instance to a Hash
  def _dump
    processed = @table.map do |key, value|
      if(value.is_a?(::Enumerable))
        flat = value.map do |v|
          v.is_a?(_klass) ? v._dump : v
        end
        val = value.is_a?(::Hash) ? __hashish[*flat.flatten(1)] : flat
      elsif(value.is_a?(_klass))
        val = value._dump
      else
        val = value
      end
      [key, val]
    end
    __hashish[*processed.flatten(1)]
  end

  # hashish:: Hash type object
  # Clears current instance data and replaces with provided hash
  def _load(hashish)
    @table.clear
    if(_root._camel_keys_action == :auto_discovery)
      starts = hashish.keys.map{|k|k[0,1]}
      unless(starts.detect{|k| k =~ /[A-Z]/})
        _camel_keys_set(:auto_disable)
      else
        _camel_keys_set(:auto_enable) unless _parent.nil?
      end
    end
    hashish.each do |key, value|
      key = key.dup
      if(value.is_a?(::Enumerable))
        flat = value.map do |v|
          v.is_a?(::Hash) ? _klass.new(v) : v
        end
        value = value.is_a?(::Hash) ? __hashish[*flat.flatten(1)] : flat
      end
      if(value.is_a?(::Hash))
        self._set(key)._load(value)
      else
        self._set(key, value)
      end
    end
    self
  end

  # target:: AttributeStruct
  # Performs a deep merge and returns the resulting AttributeStruct
  def _merge(target)
    source = _deep_copy
    dest = target._deep_copy
    if(defined?(::Chef))
      result = ::Chef::Mixin::DeepMerge.merge(source, dest)
    else
      result = source.deep_merge(dest)
    end
    _klass.new(result)
  end

  # target:: AttributeStruct
  # Performs a deep merge and updates the current instance with the
  # resulting value
  def _merge!(target)
    result = _merge(target)._dump
    _load(result)
    self
  end

  # Returns a new Hash type instance based on what is available
  def __hashish
    defined?(::Chef) ? ::Mash : ::AttributeStruct::AttributeHash
  end

  # Returns dup of value. Converts Symbol objects to strings
  def _do_dup(v)
    begin
      v.dup
    rescue
      v.is_a?(::Symbol) ? v.to_s : v
    end
  end

  # thing:: Object
  # Returns a proper deep copy
  def _deep_copy(thing=nil)
    thing ||= _dump
    if(thing.is_a?(::Enumerable))
      val = thing.map{|v| v.is_a?(::Enumerable) ? _deep_copy(v) : _do_dup(v) }
    else
      val = _do_dup(thing)
    end
    if(thing.is_a?(::Hash))
      val = __hashish[*val.flatten(1)]
    end
    val
  end

  # key:: String or Symbol
  # Processes the key and returns value based on current settings
  def _process_key(key, *args)
    key = key.to_s
    if(_camel_keys && _camel_keys_action)
      case _camel_keys_action
      when :auto_disable
        key._no_hump
      when :auto_enable
        key._hump
      end
    end
    if((_camel_keys && key._camel?) || args.include?(:force))
      key.to_s.split('_').map do |part|
        "#{part[0,1].upcase}#{part[1,part.size]}"
      end.join.to_sym
    else
      if(_camel_keys)
        # Convert so Hash doesn't make a new one and lose the meta
        key = ::CamelString.new(key) unless key.is_a?(::CamelString)
      end
      key
    end
  end

  # Helper to return class of current instance
  def _klass
    ::AttributeStruct
  end
  alias_method :class, :_klass

  # Helper to return new instance of current instance type
  def _klass_new
    n = _klass.new
    unless(_camel_keys_action == :auto_discovery)
      n._camel_keys_set(_camel_keys_action)
    end
    n._camel_keys = _camel_keys
    n._parent(self)
    n
  end

  # v:: Symbol (:auto_disable, :auto_enable)
  # Sets custom rule for processed keys
  def _camel_keys_set(v)
    @_camel_keys_set = v
  end

  # Returns value set via #_camel_keys_set
  def _camel_keys_action
    @_camel_keys_set
  end

  def _parent(obj=nil)
    @_parent = obj if obj
    @_parent
  end

  def _root
    r = self
    until(r._parent.nil?)
      r = r._parent
    end
    r
  end

  # args:: Objects
  # Helper to create Arrays with nested AttributeStructs. Proc
  # instances are automatically executed into new AttributeStruct
  # instances
  def _array(*args)
    args.map do |maybe_block|
      if(maybe_block.is_a?(::Proc))
        klass = _klass_new
        if(maybe_block.arity > 0)
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

end
