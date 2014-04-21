require 'minitest/autorun'

describe AttributeStruct do
  describe 'Collapse' do
    describe 'direct value set' do

      describe 'When values are not collapsed' do
        before do
          @struct = AttributeStruct.new
          @struct.direct.assignment 1
          @struct.direct.assignment 2
          @dump = @struct._dump
        end

        it 'should return last set value' do
          @dump['direct']['assignment'].must_equal 2
        end
      end

      describe 'When values are collapsed' do
        before do
          @struct = AttributeStruct.new
          @struct._set_state(:value_collapse => true)
          @struct.direct.assignment 1
          @struct.direct.assignment 2
          @dump = @struct._dump
        end

        it 'should return both assigned values as an array' do
          @dump['direct']['assignment'].must_equal [1,2]
        end
      end

    end

    describe 'block value set' do

      describe 'When values are not collapsed' do
        before do
          @struct = AttributeStruct.new
          @struct.direct do
            assignment true
          end
          @struct.direct do
            assignment false
          end
          @dump = @struct._dump
        end

        it 'should return last set value' do
          @dump['direct']['assignment'].must_equal false
        end

      end

      describe 'When values are collapsed' do
        before do
          @struct = AttributeStruct.new
          @struct._set_state(:value_collapse => true)
          @struct.direct do
            assignment true
          end
          @struct.direct do
            assignment false
          end
          @dump = @struct._dump
        end

        it 'should return both assigned values as an array' do
          @dump['direct'].must_equal [
            {'assignment' => true},
            {'assignment' => false}
          ]
        end

      end

    end
  end
end
