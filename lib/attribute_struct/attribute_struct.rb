class AttributeStruct
  
  class << self
    
    attr_reader :camel_keys
    attr_accessor :force_chef

    def camel_keys=(val)
      load_the_camels if val
      @camel_keys = !!val
    end

    def load_the_camels
      unless(@camels_loaded)
        require 'attribute_struct/monkey_camels'
        @camels_loaded = true
      end
    end

    def load_the_hash
      unless(@hash_loaded)
        if(defined?(Chef) || force_chef)
          require 'chef/mash'
          require 'chef/mixin/deep_merge'
        else
          require 'attribute_struct/attribute_hash'
        end
        @hash_loaded
      end
    end

  end

  attr_reader :_camel_keys
  
  def initialize(*args, &block)
    self.class.load_the_hash
    @_camel_keys = self.class.camel_keys
    @table = __hashish.new
    unless(args.empty?)
      if(args.size == 1 && args.first.is_a?(Hash))
        _load(args.first)
      end
    end
  end

  def _camel_keys=(val)
    self.class.load_the_camels if val
    @_camel_keys = !!val
  end
  
  def [](key)
    _data[_process_key(key)]
  end

  def _set(key, val=nil, &block)
    if(val)
      self.method_missing(key, val, &block)
    else
      self.method_missing(key, &block)
    end
  end
  
  def method_missing(sym, *args, &block)
    if((s = sym.to_s).end_with?('='))
      s.slice!(-1, s.length)
      sym = s
    end
    sym = _process_key(sym)
    @table[sym] ||= AttributeStruct.new
    if(!args.empty? || block)
      if(args.empty? && block)
        base = @table[sym]
        if(block.arity == 0)
          base.instance_exec(&block)
        else
          base.instance_exec(base, &block)
        end
        @table[sym] = base
      elsif(!args.empty? && block)
        base = @table[sym]
        base = self.class.new unless base.is_a?(self.class)
        @table[sym] = base
        leaf = base
        args.each do |arg|
          leaf = base[arg]
          unless(leaf.is_a?(self.class))
            leaf = self.class.new
            base._set(arg, leaf)
            base = leaf
          end
        end
        if(block.arity == 0)
          leaf.instance_exec(&block)
        else
          leaf.instance_exec(leaf, &block)
        end
      else
        @table[sym] = args.first
      end
    end
    @table[sym]
  end

  def nil?
    _data.empty?
  end

  def _keys
    _data.keys
  end
  
  def _data
    @table
  end

  def _dump
    __hashish[
      *(@table.map{|key, value|
          [key, value.is_a?(self.class) ? value._dump : value]
        }.flatten(1))
    ]
  end

  def _load(hashish)
    @table.clear
    hashish.each do |key, value|
      if(value.is_a?(Hash))
        self._set(key)._load(value)
      else
        self._set(key, value)
      end
    end
    self
  end

  def _merge(target)
    source = deep_copy
    dest = target.deep_copy
    if(defined?(Mash))
      result = Chef::Mixin::DeepMerge.merge(source, dest)
    else
      result = source.deep_merge(dest)
    end
    AttributeStruct.new(result)
  end

  def _merge!(target)
    result = _merge(target)._dump
    _load(result)
    self
  end
  
  def __hashish
    defined?(Mash) ? Mash : AttributeHash
  end
  
  def do_dup(v)
    begin
      v.dup
    rescue
      v.is_a?(Symbol) ? v.to_s : v
    end
  end

  def deep_copy(thing=nil)
    thing ||= _dump
    if(thing.is_a?(Enumerable))
      val = thing.map{|v| v.is_a?(Enumerable) ? deep_copy(v) : do_dup(v) }
    else
      val = do_dup(thing)
    end
    if(thing.is_a?(Hash))
      val = __hashish[*val.flatten(1)]
    end
    val
  end

  def _process_key(key)
    key = key.to_s
    if(_camel_keys && key._camel?)
      key.to_s.split('_').map do |part|
        "#{part[0,1].upcase}#{part[1,part.size]}"
      end.join.to_sym
    else
      if(_camel_keys)
        # Convert so Hash doesn't make a new one and lose the meta
        key = CamelString.new(key) unless key.is_a?(CamelString)
      end
      key
    end
  end
end
