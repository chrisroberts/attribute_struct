require_relative "./base"

describe AttributeStruct do
  describe ".camel_style=" do
    it "sets style when provided supported type" do
      expect {
        described_class.camel_style = :no_leading_hump
      }.not_to raise_error
    end
  end
end
