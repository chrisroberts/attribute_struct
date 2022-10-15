require "attribute_struct"
require "minitest/autorun"

describe AttributeStruct do
  before do
    @struct = AttributeStruct.new
  end

  let(:struct) { @struct }

  describe "Instance objectification" do
    it "should locate constant only when enabled" do
      value(struct.String.class).must_equal AttributeStruct
      struct.objectify!
      value(struct.String).must_equal String
    end

    it "should automatically objectify offspring" do
      struct.objectify!
      value(struct.nested.item.objectified?).must_equal true
    end
  end

  describe "Instance kernelization" do
    it "should not have Kernel instance methods available until enabled" do
      value(struct.rand.class).must_equal AttributeStruct
      struct.kernelify!
      value(struct.rand.class).must_equal Float
    end

    it "should automatically kernelify offspring" do
      struct.kernelify!
      value(struct.nested.item.kernelified?).must_equal true
      value(struct.nested.item.rand.class).must_equal Float
    end
  end
end
