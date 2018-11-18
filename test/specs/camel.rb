require "minitest/autorun"

describe AttributeStruct do
  describe "Camel usage" do
    before do
      AttributeStruct.camel_keys = true
      @struct = AttributeStruct.new do
        value_one true
        value_two do
          nesting true
        end
      end
    end
    after do
      AttributeStruct.camel_keys = false
    end

    it "should camel case keys when dumped" do
      @struct._dump.keys.must_include "ValueOne"
      @struct._dump.keys.must_include "ValueTwo"
    end

    it "should allow explicit disable on keys" do
      @struct._set("not_camel"._no_hump, true)
      @struct._dump.keys.must_include "not_camel"
    end

    it "should allow implicit disable on nested structs" do
      @struct.disable_camel do |struct|
        struct._camel_keys_set(:auto_disable)
        not_camel true
        not_camel_nest do
          no_camel_here true
        end
      end
      dump = @struct._dump
      dump["DisableCamel"][:not_camel].must_equal true
      dump["DisableCamel"][:not_camel_nest][:no_camel_here].must_equal true
      dump["ValueOne"].must_equal true
      dump["ValueTwo"]["Nesting"].must_equal true
    end
  end

  describe "Camel styling" do
    it "should automatically lead with upcase" do
      @struct = AttributeStruct.new
      @struct._camel_keys = true
      @struct.value_one true
      @struct.value_two { nesting true }
      dump = @struct._dump
      dump["ValueOne"].must_equal true
      dump["ValueTwo"].must_equal "Nesting" => true
    end

    it "should allow defaulting to lead lowercase" do
      @struct = AttributeStruct.new
      @struct._camel_keys = true
      @struct._camel_style = :no_leading_hump
      @struct.value_one true
      @struct.value_two { nesting true }
      dump = @struct._dump
      dump["valueOne"].must_equal true
      dump["valueTwo"].must_equal "nesting" => true
    end

    it "should allow mixing styles" do
      @struct = AttributeStruct.new
      @struct._camel_keys = true
      @struct._camel_style = :no_leading_hump
      @struct.value_one true
      @struct.value_two { nesting true }
      x = @struct.value_three
      x._camel_style = :leading_hump
      x.inside_nesting true
      dump = @struct._dump
      dump["valueOne"].must_equal true
      dump["valueTwo"].must_equal "nesting" => true
      dump["valueThree"].must_equal "InsideNesting" => true
    end

    it "should allow key level overrides" do
      @struct = AttributeStruct.new
      @struct._camel_keys = true
      @struct._camel_style = :no_leading_hump
      @struct.value_one true
      @struct.value_two.set!("nesting".leading_hump!).value true
      x = @struct.value_three
      x._camel_style = :leading_hump
      x.set!("inside_nesting".no_leading_hump!).value true
      dump = @struct._dump
      dump["valueOne"].must_equal true
      dump["valueTwo"]["Nesting"].must_equal "value" => true
      dump["valueThree"]["insideNesting"].must_equal "Value" => true
    end
  end

  describe "Camel enabled imports" do
    before do
      @struct = AttributeStruct.new
      @struct._camel_keys = true
      @struct._camel_keys_set(:auto_discovery)
      @struct._load(
        {
          "Fubar" => {
            "FooBar" => true,
            "FeeBar" => {
              "FauxBar" => "done",
            },
            "FooDar" => {
              "snake_case" => {
                "still_snake" => {
                  "NowCamel" => {
                    "CamelCamel" => "yep, a camel",
                  },
                },
              },
            },
          },
        }
      )
      @struct._camel_keys_set(nil)
    end

    it "should properly export keys after discovery" do
      @struct.fubar.new_bar.halt "new_value"
      @struct.fubar.foo_dar.snake_case.new_snake "snake!"
      @struct.fubar.foo_dar.snake_case.still_snake.now_camel.new_camel "a camel!"
      hash = @struct._dump
      hash["Fubar"]["NewBar"]["Halt"].must_equal "new_value"
      hash["Fubar"]["FooDar"]["snake_case"]["new_snake"].must_equal "snake!"
      hash["Fubar"]["FooDar"]["snake_case"]["still_snake"]["NowCamel"]["NewCamel"].must_equal "a camel!"
    end
  end

  it "should not camel case when forced if struct has camel casing disabled" do
    struct = AttributeStruct.new
    struct._camel_keys = false
    struct._process_key("my_key", :force).must_equal "my_key"
  end
end
