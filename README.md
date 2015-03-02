# AttributeStruct

This is a helper library that essentially builds hashes. It
wraps hash building with a nice DSL to make it slightly cleaner,
more robust, and provide extra features.

## Build Status

* [![Build Status](https://api.travis-ci.org/chrisroberts/attribute_struct.png)](https://travis-ci.org/chrisroberts/attribute_struct)

## Usage

```ruby
require 'attribute_struct'

struct = AttributeStruct.new
struct.settings do
  ui.admin do
    enabled true
    port 8080
    bind '*'
  end
  ui.public do
    enabled true
    port 80
    bind '*'
  end
  client('general') do
    enabled false
  end
end
```

Now we have an attribute structure that we can
query and modify. To force it to a hash, we
can simply dump it:

```ruby
require 'pp'

pp struct._dump
```

which gives:

```ruby
{"settings"=>
  {"ui"=>
    {"admin"=>{"enabled"=>true, "port"=>8080, "bind"=>"*"},
     "public"=>{"enabled"=>true, "port"=>80, "bind"=>"*"}},
   "client"=>{"general"=>{"enabled"=>false}}}}
```

## IRB

IRB expects some things to be around like `#inspect` and `#to_s`. Before
using `AttributeStruct` in IRB, enable compat mode:

```ruby
> require 'attribute_struct'
> AttributeStruct.irb_compat!
```

## Information

* Repo: https://github.com/chrisroberts/attribute_struct
