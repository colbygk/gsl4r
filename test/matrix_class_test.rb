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

  def test_gsl_matrix_set_values()
    assert_nothing_raised do
      matrix = GSL_Matrix.create( SIZE,SIZE )

      arys = Array.new(SIZE)
      (0..SIZE-1).each { |i|
	arys[i] = (0..SIZE-1).to_a.collect { |j| i*j
	}
      }

      matrix.set_with_arrays( arys ) 
      m = matrix.values
      (0..SIZE-1).each { |i| (0..SIZE-1).each { |j| assert m[i][j] == i*j } }

    end
  end

  def test_gsl_matrix_set_all()
    assert_nothing_raised do
      matrix = GSL_Matrix.create( SIZE, SIZE )

      matrix.set_all( 5 )
      m = matrix.values
      s = 0.0
      m.each { |i|
	i.each { |j|
	  s = s + j
	}
      }

      assert (SIZE*SIZE*5) == s
    end
  end

  # picks 4 columns from the last 2 rows starting at 1,1
  def test_gsl_matrix_submatrix()
    assert_nothing_raised do
      m1 = GSL_Matrix.create( SIZE, SIZE )
      m1.set_with_arrays( [[1,2,3,4,5,6,7],[1,2,3,4,5,6,7],[1,2,3,4,5,6,7]] )
      m2 = m1.submatrix( 1,1, 2,4 )
      assert m2.values == [[2.0, 3.0, 4.0, 5.0], [2.0, 3.0, 4.0, 5.0]]
    end
  end

  # TODO: build array and prepopulate
  def test_gsl_matrix_view_array()
    assert_nothing_raised do
      d = ::FFI::MemoryPointer.new :double

    end
  end

  def test_gsl_matrix_view_vector()
    assert_nothing_raised do
      v = ::GSL4r::Vector::GSL_Vector.create(10)
      v.set_with_array( [1,2,3,4,5,6,7,8,9,10] )

      m1 = ::GSL4r::Matrix::Methods::gsl_matrix_view_vector( v, 2, 2 )

      assert m1.length == [2,2,2]
      assert m1.values == [[1,2],[3,4]]

      m1 = ::GSL4r::Matrix::Methods::gsl_matrix_view_vector_with_tda( v, 2, 2, 5 )

      assert m1.length == [2,2,5]
      assert m1.values == [[1,2],[6,7]]
    end
  end



end
