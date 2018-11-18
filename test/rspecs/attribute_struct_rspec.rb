require_relative "./base"

describe AttributeStruct do
  describe ".camel_style=" do
    it "sets style when provided supported type" do
      expect {
        described_class.camel_style = :no_leading_hump
      }.not_to raise_error
    end

    it "raises error when invalid type is provided" do
      expect {
        described_class.camel_style = :invalid
      }.to raise_error(ArgumentError)
    end
  end

  describe ".camel_keys=" do
    it "sets camel keys value to true" do
      described_class.camel_keys = true
      expect(described_class.camel_keys).to eq(true)
    end

    it "sets camel keys value to false" do
      described_class.camel_keys = false
      expect(described_class.camel_keys).to eq(false)
    end

    it "loads camel key support when set to true" do
      expect(described_class).to receive(:load_the_camels)
      described_class.camel_keys = true
    end

    it "does not load camel key support when set to false" do
      expect(described_class).not_to receive(:load_the_camels)
      described_class.camel_keys = false
    end
  end

  describe "#key?" do
    let(:struct) {
      AttributeStruct.new { fubar true }
    }

    it "should return true when key is defined" do
      expect(struct.key?(:fubar)).to eq(true)
    end

    it "should return false when key is not defined" do
      expect(struct.key?(:foobar)).to eq(false)
    end

    it "should not modify struct when key exists" do
      start_state = struct.dump!
      expect(struct.key?(:fubar)).to eq(true)
      expect(struct.dump!).to eq(start_state)
    end

    it "should not modify struct when key does not exist" do
      start_state = struct.dump!
      expect(struct.key?(:foobar)).to eq(false)
      expect(struct.dump!).to eq(start_state)
    end
  end
end
