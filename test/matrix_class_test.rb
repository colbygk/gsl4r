$: << File.join('..','lib')

require 'rubygems'
require 'ffi'

require 'test/unit'
require 'test/unit/autorunner'

require 'gsl4r'
require 'gsl4r/matrix'

include GSL4r::Matrix
include FFI

class MatrixTests < Test::Unit::TestCase

  SIZE=50

  def test_gsl_matrix_alloc_and_free()
    assert_nothing_raised do
      matrixptr = MemoryPointer.new :pointer
      matrixptr = GSL4r::Matrix::Methods::gsl_matrix_alloc( SIZE, SIZE )
      GSL4r::Matrix::Methods::gsl_matrix_free( matrixptr )
    end
  end

  # freed by leaving scope
  def test_gsl_matrix_calloc()
    assert_nothing_raised do
      matrixptr = MemoryPointer.new :pointer
      matrixptr = GSL4r::Matrix::Methods::gsl_matrix_calloc( SIZE, SIZE )
      matrix = GSL_Matrix.new( matrixptr )

      m = matrix.values
      assert m.length == SIZE

      m.each { |i|
       i.each { |j|
 	 assert j == 0
       }
      }

    end
  end

  def test_gsl_matrix_new()
    assert_nothing_raised do
      matrix = GSL_Matrix.create( SIZE,SIZE )

      assert matrix.length == [SIZE,SIZE,SIZE]
    end
  end

  class ::GSL4r::Matrix::GSL_Matrix_Monitor < ::GSL4r::Matrix::GSL_Matrix
    def self.release(ptr)
      super
      $release_count = $release_count + 1
    end
  end

  class ::GSL4r::Matrix::GSL_Matrix_Cast_Monitor < ::GSL4r::Matrix::GSL_Matrix_Cast
    def self.release(ptr)
      super
      $release_count = $release_count + 1
    end
  end

  # tests using a cast object to retain a reference
  # to a memory pointer, without freeing it when the
  # object is garbage collected.
  def test_gsl_matrix_cast()
    $release_count = 0

    assert_nothing_raised do
      matrixptr = MemoryPointer.new :pointer
      matrixptr = GSL4r::Matrix::Methods::gsl_matrix_alloc( SIZE,SIZE )

      m1=GSL4r::Matrix::GSL_Matrix_Monitor.new( matrixptr )
      m2=GSL4r::Matrix::GSL_Matrix_Cast_Monitor.new( matrixptr )

      assert m1.length == m2.length
    end

    m1=nil
    m2=nil
    GC.start

    assert $release_count == 1

  end

end
