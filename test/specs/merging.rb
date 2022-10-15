require "minitest/autorun"

describe AttributeStruct do
  describe "Merging usage" do
    before do
      @struct1 = AttributeStruct.new do
        value1 true
        value2 do
          nesting true
        end
      end
      @struct2 = AttributeStruct.new do
        value2 do
          nesting false
          squashing true
        end
      end
    end

    describe "new struct from merge" do
      before do
        @struct = @struct1._merge(@struct2)._dump
      end

      it "should have correct value for value1" do
        value(@struct["value1"]).must_equal true
      end

      it "should have correct value for squashing" do
        value(@struct["value2"]["squashing"]).must_equal true
      end

      it "should have correct value for nesting" do
        value(@struct["value2"]["nesting"]).must_equal false
      end
    end

    describe "update struct from merge" do
      before do
        @struct = AttributeStruct.new do
          test_value true
        end
        @struct._merge!(@struct1)
        @struct = @struct._dump
      end

      it "should contain test_value" do
        value(@struct["test_value"]).must_equal true
      end

      it "should contain value1" do
        value(@struct["value1"]).must_equal true
      end
    end
  end
end
