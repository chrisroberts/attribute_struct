require "minitest/autorun"

describe AttributeStruct do
  describe "multi parameter set" do
    it "should allow multi set via block" do
      struct = AttributeStruct.new do
        key "value", :with_hash => true
      end._dump
      value(struct["key"]).must_equal ["value", "with_hash" => true]
    end

    it "should allow multi set via direct assignment" do
      struct = AttributeStruct.new
      struct.key "value", :with_hash => true
      struct = struct._dump
      value(struct["key"]).must_equal ["value", "with_hash" => true]
    end

    it "should allow multi set when collapsing" do
      struct = AttributeStruct.new
      struct._set_state(:value_collapse => true)
      struct.key "value1", :with_hash => true
      struct.key "value2", :with_hash => true
      struct = struct._dump
      value(struct["key"].first).must_equal ["value1", "with_hash" => true]
      value(struct["key"].last).must_equal ["value2", "with_hash" => true]
    end

    it "should allow mixed value multi set when collapsing" do
      struct = AttributeStruct.new
      struct._set_state(:value_collapse => true)
      struct.key "value1", :with_hash => true
      struct.key "value2", :with_hash => true
      struct.key "value3"
      struct.key "value4"
      struct.key "value5", :with_hash => true
      struct = struct._dump
      value(struct["key"][0]).must_equal ["value1", "with_hash" => true]
      value(struct["key"][1]).must_equal ["value2", "with_hash" => true]
      value(struct["key"][2]).must_equal "value3"
      value(struct["key"][3]).must_equal "value4"
      value(struct["key"][4]).must_equal ["value5", "with_hash" => true]
    end
  end
end
