$: << File.join('..','lib')

require 'rubygems'
require 'ffi'

require 'test/unit'
require 'test/unit/autorunner'

require 'gsl4r'
require 'gsl4r/vector'

include GSL4r::Vector
include FFI

class VectorTests < Test::Unit::TestCase

  SIZE=50

  def test_gsl_vector_alloc_and_free()
    assert_nothing_raised do
      vecptr = MemoryPointer.new :pointer
      vecptr = GSL4r::Vector::Methods::gsl_vector_alloc( SIZE )
      GSL4r::Vector::Methods::gsl_vector_free( vecptr )
    end
  end

  # freed by leaving scope
  def test_gsl_vector_calloc()
    assert_nothing_raised do
      vecptr = MemoryPointer.new :pointer
      vecptr = GSL4r::Vector::Methods::gsl_vector_calloc( SIZE )
      vec = GSL_Vector.new( vecptr )

      v = vec.values
      assert v.length == SIZE
      v.each { |i| assert i == 0 }

    end
  end

  def test_gsl_vector_new()
    assert_nothing_raised do
      vec = GSL_Vector.create( SIZE )

      assert vec.length == SIZE
    end
  end

  class ::GSL4r::Vector::GSL_Vector_Monitor < ::GSL4r::Vector::GSL_Vector
    def self.release(ptr)
      super
      $release_count = $release_count + 1
    end
  end

  class ::GSL4r::Vector::GSL_Vector_Cast_Monitor < ::GSL4r::Vector::GSL_Vector_Cast
    def self.release(ptr)
      super
      $release_count = $release_count + 1
    end
  end

  # tests using a cast object to retain a reference
  # to a memory pointer, without freeing it when the
  # object is garbage collected.
  def test_gsl_vector_cast()
    $release_count = 0

    assert_nothing_raised do
      vecptr = MemoryPointer.new :pointer
      vecptr = GSL4r::Vector::Methods::gsl_vector_alloc( SIZE )

      v1=GSL4r::Vector::GSL_Vector_Monitor.new( vecptr )
      v2=GSL4r::Vector::GSL_Vector_Cast_Monitor.new( vecptr )

      assert v1.length == v2.length
    end

    v1=nil
    v2=nil
    GC.start

    assert $release_count == 1

  end

  def test_gsl_vector_set_values()
    assert_nothing_raised do
      vec = GSL_Vector.create( SIZE )

      vec.set_with_array( (0..SIZE-1).to_a.collect { |i| i=i*i } )
      v = vec.values
      (0..SIZE-1).each { |i| assert v[i] == i*i }

    end
  end

  def test_gsl_vector_set_all()
    assert_nothing_raised do
      vec = GSL_Vector.create( SIZE )

      vec.set_all( 5 )
      v = vec.values
      s = 0.0
      (0..SIZE-1).each { |i| s = s + v[i] }

      assert (SIZE*5) == s
    end
  end

  def test_gsl_vector_subvector()
    assert_nothing_raised do
      vec = GSL_Vector.create( SIZE )

      a = Array.new( SIZE )
      vec.set_with_array( (0..SIZE-1).to_a.collect { |i| i=i+1.0 } )

      subvec = vec.subvector( 10, 5 )

      v = subvec.values

      test_a = (0..4).to_a.collect { |i| i=i+11.0 }

      assert v == test_a
    end
  end

end
