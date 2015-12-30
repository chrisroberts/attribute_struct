require 'attribute_struct'
require 'attribute_struct/monkey_camels'
require 'minitest/autorun'

describe AttributeStruct do
  describe 'Basic usage' do
    describe 'instance based population' do
      before do
        @struct = AttributeStruct.new
        @struct.method.based.access 100
        @struct.method('and', 'parameter', 'based').access 100
        @struct.block do
          based.access 100
        end
        @struct.block('and', 'parameter', 'based') do
          nested('with', 'block') do
            access 100
          end
          access 100
        end
        @struct.block_only do
          access 100
        end
        @struct._set('1') do
          value 100
        end
        @struct_hash = @struct._dump
      end

      it 'allows method based access' do
        @struct.method.based['access'].must_equal 100
        @struct_hash['method']['based']['access'].must_equal 100
      end

      it 'allows method and parameter based access' do
        @struct_hash['method']['and']['parameter']['based']['access'].must_equal 100
      end

      it 'allows block based access' do
        @struct.block.based._dump['access'].must_equal 100
      end

      it 'allows block and parameter based access' do
        @struct.block.and.parameter.based['access'].must_equal 100
        @struct.block.and.parameter.based.nested.with.block['access'].must_equal 100
        @struct_hash['block']['and']['parameter']['based']['access'].must_equal 100
        @struct_hash['block']['and']['parameter']['based']['nested']['with']['block']['access'].must_equal 100
      end

      it 'allows block only access' do
        @struct.block_only['access'].must_equal 100
        @struct_hash['block_only']['access'].must_equal 100
      end

      it 'allows hash style access' do
        @struct['method'][:based]['access'].must_equal 100
        @struct_hash['method']['based']['access'].must_equal 100
      end

      it 'allows _set for invalid method names' do
        @struct['1']['value'].must_equal 100
        @struct_hash['1']['value'].must_equal 100
      end

    end

    describe 'block based creation' do
      before do
        @struct = AttributeStruct.new do
          enable true
          access.user true
          access do
            port 80
            transport :udp
          end
        end
      end

      it 'creates struct with block content' do
        @struct['enable'].must_equal true
        @struct.access['user'].must_equal true
        @struct.access['port'].must_equal 80
        @struct.access['transport'].must_equal :udp
      end

      it 'should have access to parent data' do
        @struct.parent_access.nest1 do
          nest2.nest3 do
            value _parent._parent._parent.keys!.first
          end
        end
        result = @struct._dump.to_smash
        result.get(:parent_access, :nest1, :nest2, :nest3, :value).must_equal 'nest1'
      end

    end

    describe 'nil behavior' do
      before do
        @struct = AttributeStruct.new
      end

      it 'should return as nil' do
        @struct.nil?.must_equal true
      end

      it 'should not equal nil' do
        @struct.wont_be nil
      end

    end

    describe 'array helper' do
      before do
        @struct = AttributeStruct.new do
          my_array _array(
            -> {
              working true
            },
            :item
          )
        end
      end

      it 'should contain an array at my_array' do
        @struct['my_array'].must_be_kind_of Array
      end

      it 'should contain symbol in array' do
        @struct['my_array'].must_include :item
      end

      it 'should contain an AttrubuteStruct instance in array' do
        assert @struct['my_array'].detect{|i| i.is_a?(AttributeStruct)}
      end

      it 'should contain working attribute in array struct' do
        @struct['my_array'].detect{|i| i.is_a?(AttributeStruct)}.working.must_equal true
      end
    end

    describe 'entry deletion' do
      before do
        @struct = AttributeStruct.new do
          value1 true
          value2 true
        end
        @struct._delete(:value2)
      end

      it 'should contain value1' do
        @struct['value1'].must_equal true
      end

      it 'should not contain value2 in keys' do
        @struct._keys.wont_include 'value2'
      end

      it 'should report nil for value2' do
        @struct['value2'].must_be_nil
      end
    end

    describe 'dumps' do
      before do
        @struct = AttributeStruct.new do
          value1 true
          value2 do
            nested true
          end
          value3 do
          end
          value4 nil
        end
      end

      it 'should dump to a hash type value' do
        @struct._dump.must_be_kind_of Hash
      end

      it 'should include all defined values' do
        dump = @struct._dump
        dump['value1'].must_equal true
        dump['value2'].must_be_kind_of Hash
        dump['value2']['nested'].must_equal true
        dump['value3'].must_equal nil
        dump['value4'].must_equal nil
      end
    end

    describe 'loads' do
      before do
        @hash = {'value1' => true, 'value2' => {'nested' => true}}
        @struct = AttributeStruct.new(@hash)
      end

      it 'should include all values defined in hash' do
        @struct['value1'].must_equal true
        @struct['value2'].nested.must_equal true
      end
    end

    describe 'setting Hash type' do

      before do
        @struct = AttributeStruct.new
      end

      it 'should convert into struct when state is set' do
        @struct._set_state(:hash_load_struct => true)
        @struct.value({:a => 1, :b => 2, :c => {:x => 3}})
        @struct.value.c.x.must_equal 3
      end

      it 'should not convert into struct when state is unset' do
        @struct._set_state(:hash_load_struct => false)
        @struct.value({:a => 1, :b => 2, :c => {:x => 3}})
        @struct.value.must_be_kind_of Hash
      end

    end

  end
end
