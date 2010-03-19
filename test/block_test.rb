$: << File.join('..','lib')

require 'rubygems'
require 'ffi'

require 'test/unit'
require 'test/unit/autorunner'

require 'gsl4r'
require 'gsl4r/block'

include GSL4r::Block
include FFI

class BlockTests < Test::Unit::TestCase

  SIZE=50

  def test_gsl_block_alloc_and_free()
    assert_nothing_raised do
      blkptr = MemoryPointer.new :pointer
      blkptr = GSL4r::Block::Methods::gsl_block_alloc( SIZE )
      GSL4r::Block::Methods::gsl_block_free( blkptr )
    end
  end

  # freed by leaving scope
  def test_gsl_block_calloc()
    assert_nothing_raised do
      blkptr = MemoryPointer.new :pointer
      blkptr = GSL4r::Block::Methods::gsl_block_calloc( SIZE )
      blk = GSL_Block.new( blkptr )

      v = blk.values
      assert v.length == SIZE
      v.each { |i| assert i == 0 }

    end
  end

  def test_gsl_block_new()
    assert_nothing_raised do
      blkptr = MemoryPointer.new :pointer
      blkptr = GSL4r::Block::Methods::gsl_block_alloc( SIZE )

      blk = GSL_Block.new( blkptr )
      assert blk.length == SIZE
    end
  end

  class ::GSL4r::Block::GSL_Block_Monitor < ::GSL4r::Block::GSL_Block
    def self.release(ptr)
      super
      $release_count = $release_count + 1
    end
  end

  class ::GSL4r::Block::GSL_Block_Cast_Monitor < ::GSL4r::Block::GSL_Block_Cast
    def self.release(ptr)
      super
      $release_count = $release_count + 1
    end
  end

  # tests using a cast object to retain a reference
  # to a memory pointer, without freeing it when the
  # object is garbage collected.
  def test_gsl_block_cast()
    $release_count = 0

    assert_nothing_raised do
      blkptr = MemoryPointer.new :pointer
      blkptr = GSL4r::Block::Methods::gsl_block_alloc( SIZE )

      b1=GSL4r::Block::GSL_Block_Monitor.new( blkptr )
      b2=GSL4r::Block::GSL_Block_Cast_Monitor.new( blkptr )

      assert b1.length == b2.length
    end

    b1=nil
    b2=nil
    GC.start

    assert $release_count == 1

  end

  def test_gsl_block_set_values()
    assert_nothing_raised do
      blkptr = MemoryPointer.new :pointer
      blkptr = GSL4r::Block::Methods::gsl_block_alloc( SIZE )
      blk = GSL_Block.new( blkptr )

      blk.set( (1..SIZE).to_a.collect { |i| i=i*i } )
      v = blk.values
      (1..SIZE).each { |i| assert v[i-1] == i*i }

    end
  end



end
