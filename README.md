# AttributeStruct

AttributeStruct is a DSL helper library. It provides support for programmatic
generation of complex data structures.

## How it works

Under the hood, AttributeStruct makes use of Ruby's `BasicObject` class and the
`#method_missing` method to bring a clean and concise way of generating data
structures. Deeply nested Hashes can be built using method chaining, block
structures, or both. Evaluation of a structure is performed top down, allowing
access to previously set data values within the structure during evaluation.

## Examples

### Setting values

#### Method chaining

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a.deeply.nested.hash true
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nested"=>{"hash"=>true}}}}}}
```

#### Block nesting

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this do
    is do
      a do
        deeply do
          nested do
            hash true
          end
        end
      end
    end
  end
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nested"=>{"hash"=>true}}}}}}
```

#### Mixed block nesting and method chaining

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a do
    deeply.nested do
      hash true
    end
  end
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nested"=>{"hash"=>true}}}}}}
```

### Structure re-entry

#### Block re-entry

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a do
    deeply.nested do
      hash true
    end
    deeply do
      nested.other_hash true
    end
  end
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nested"=>{"hash"=>true,"other_hash"=>true}}}}}}
```

#### Method re-entry

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a do
    deeply.nested do
      hash true
    end
  end
  this.is.a.deeply.nested.other_hash true
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nested"=>{"hash"=>true,"other_hash"=>true}}}}}}
```

### Data removal

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a do
    deeply.nested do
      hash true
    end
  end
  this.is.a.deeply.nested.other_hash true
  this.is.a.deeply.nested.delete!(:hash)
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nested"=>{"other_hash"=>true}}}}}}
```

### Data Access

#### Current data

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a do
    deeply.nested do
      hash 'my_value'
    end
  end
  this.is.a.deeply.nested do
    other_hash data![:hash]
  end
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nested"=>{"hash"=>"my_value","other_hash"=>"my_value"}}}}}}
```

#### Current data keys

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a do
    deeply.nested do
      hash 'my_value'
    end
  end
  this.is.a.deeply.nested do
    other_hash keys!
  end
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nested"=>{"hash"=>"my_value","other_hash"=>["hash"]}}}}}}
```

### Hierarchy access

#### Parent structure

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a do
    deeply do
      state 'sunny'
      nested do
        hash parent!.state
      end
    end
  end
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"state"=>"sunny", "nested"=>{"hash"=>"sunny"}}}}}}
```

#### Root structure

```ruby
require 'attribute_struct'

AttributeStruct.new do
  this.is.a do
    deeply do
      state 'sunny'
      nested do
        hash root!.this.is.a.deeply.state
      end
    end
  end
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"state"=>"sunny", "nested"=>{"hash"=>"sunny"}}}}}}
```

### Camel case

#### Camel case keys

```ruby
require 'attribute_struct'

AttributeStruct.new do
  self._camel_keys = true
  this.is.a.deeply.nested_camel.hash true
end.dump!

# => {"This"=>{"Is"=>{"A"=>{"Deeply"=>{"NestedCamel"=>{"Hash"=>true}}}}}}
```

#### Camel case with lead lower

```ruby
require 'attribute_struct'

AttributeStruct.new do
  self._camel_keys = true
  self._camel_style = :no_leading
  this.is.a.deeply.nested_camel.hash true
end.dump!

# => {"this"=>{"is"=>{"a"=>{"deeply"=>{"nestedCamel"=>{"hash"=>true}}}}}}
```

#### Disable camel on individual key

```ruby
require 'attribute_struct'

AttributeStruct.new do
  self._camel_keys = true
  this.is.a.deeply.nested_camel.hash true
  this.set!('horse'.no_hump!, true)
end.dump!

# => {"This"=>{"Is"=>{"A"=>{"Deeply"=>{"NestedCamel"=>{"Hash"=>true}}}}},"horse" => true}
```

## In the wild

Libraries utilizing AttributeStruct:

* SparkleFormation: http://www.sparkleformation.io
* Bogo Config: https://github.com/spox/bogo-config

## Information

* Repo: https://github.com/chrisroberts/attribute_struct
