#
# == Other Info
#
#
# Author::	Colby Gutierrez-Kraybill
# Version::	$Id$
#

require 'rubygems'
require 'ffi'

require 'gsl4r/util'
require 'gsl4r/harness'
require 'gsl4r/block'
require 'gsl4r/vector'

module GSL4r
  module Matrix

    extend ::FFI::Library

    # layout/cast/struct pattern /lifted from
    # http://wiki.github.com/ffi/ffi/examples
    module MatrixLayout
      def self.included(base)
	base.class_eval do
	  layout :size1, :size_t,
	    :size2,	:size_t,
	    :tda,	:size_t,
	    :data,	:pointer,
	    :block,	:pointer,
	    :owner,	:int
	end
      end
    end

    def get_matrix_row_size( a_matrix )
      return a_matrix.get_ulong(0) # :size1
    end
    module_function :get_matrix_row_size

    def get_matrix_col_size( a_matrix )
      return a_matrix.get_ulong(1) # :size2
    end
    module_function :get_matrix_col_size

    def get_matrix_tda( a_matrix )
      return a_matrix.get_ulong(2) # :tda aka trailing dimension
    end
    module_function :get_matrix_tda

    class GSL_Matrix < FFI::ManagedStruct
      include ::GSL4r::Matrix::MatrixLayout

      attr_accessor :matrixptr

      GSL_PREFIX = "gsl_matrix_"
      GSL_MODULE = ::GSL4r::Matrix

      include ::GSL4r::Util::AutoPrefix

      def self.create( size1, size2 )
	@matrixptr = ::FFI::MemoryPointer.new :pointer
	@matrixptr = ::GSL4r::Matrix::Methods::gsl_matrix_alloc( size1, size2 )

	GSL_Matrix.new( @matrixptr )
      end

      def self.release(ptr)
	::GSL4r::Matrix::Methods::gsl_matrix_free(ptr)
      end

      def length
	return self[:size1], self[:size2], self[:tda]
      end

      # TODO: needs work
      def values
	r,c,t = length

	alldata = self[:data].get_array_of_double(0, (t*c))

	allvalues = []
	
	(0..r-1).each { |i|
	  allvalues << alldata[(c*i),c]
	}

	return allvalues
      end

      # TODO: needs work
      def set_with_arrays( a )
	cc = 0
	rl,cl,tl = length

	store = Array.new
	a.each { |i|
	  i.each { |j|
	    store << j
	    cc += 1
	  }
	  if ( cc < cl-1 ) # pad out any missing values
	    (cc..cl-1).each { store << 0.0 }
	  end
	  cc = 0
	}
	self[:data].put_array_of_double(0,store)
      end

=begin
      def minmax
	min = ::FFI::MemoryPointer.new :double
	max = ::FFI::MemoryPointer.new :double

	::GSL4r::Vector::Methods::gsl_vector_minmax( self, min, max )

	rmin = min.get_double(0)
	rmax = max.get_double(0)
	min = nil
	max = nil

	return rmin, rmax
      end

      def minmax_index
	min = ::FFI::MemoryPointer.new :size_t
	max = ::FFI::MemoryPointer.new :size_t

	::GSL4r::Vector::Methods::gsl_vector_minmax_index( self, min, max )

	# TODO: Submit request that get_size_t be added to FFI?
	if min.size > FFI::type_size( :ulong )
	  raise RuntimeError, "unsigned long < size_t on this platform!"
	end

	rmin = min.get_ulong(0)
	rmax = max.get_ulong(0)
	min = nil
	max = nil

	return rmin, rmax
      end
=end

      # Play nice and have these methods show up in case someone
      # is digging around for them using these reflection routines
      # Note: this won't show the shortened named forms that
      # will automatically be generated when called.
      def methods
	a = super
	a + GSL_MODULE::Methods.methods.grep(/^#{GSL_PREFIX}/)
      end
      
      class << self
	def r_type()
	  "GSL_Matrix"
	end
	def r_initializer()
	  r_type + ".create(3,3)"
	end
	def r_equals()
	  " == "
	end
	def r_answer( name )
	  "#{name}.values"
	end
	def r_assignment( name )
	  "#{name}.set([[1.0,2.0,3.0],[4.0,5.0,6.0]])" # make c_assignment ...
	end
	def c_to_r_assignment(m1,m2)
	  "printf(\\\"  #{m1}.set(#{c_answer_guts(m2)});\\n"
	end
        def c_answer_guts( name )
	  "[[%.15g,%.15g,%.15g],[%.15g,%.15g,%.15g]])\\\\n\\\",gsl_matrix_get(#{name},0,0),gsl_matrix_get(#{name},0,1),gsl_matrix_get(#{name},0,2),gsl_matrix_get(#{name},1,0),gsl_matrix_get(#{name},1,1),gsl_matrix_get(#{name},1,2)"
	end
	def c_type()
	  "gsl_matrix *"
	end
	def c_assignment( name )
	  "gsl_matrix_set(#{name},0,0,1.0); gsl_matrix_set(#{name},0,1,2.0); gsl_matrix_set(#{name},0,2,3.0); gsl_matrix_set(#{name},1,0,4.0); gsl_matrix_set(#{name},1,1,5.0); gsl_matrix_set(#{name},1,2,6.0);"
	end
	def c_answer( name )
	  "printf(\\\"#{c_answer_guts(name)});\\n"
	end
	def c_equals()
	end
	def c_initializer( name )
	  "#{name} = gsl_matrix_alloc(3,3); "
	end
      end # class << self

    end # GSL_Matrix

    class GSL_Matrix_Cast < FFI::Struct
      include ::GSL4r::Matrix::MatrixLayout

      GSL_PREFIX = "gsl_matrix_"
      GSL_MODULE = ::GSL4r::Matrix

      include ::GSL4r::Util::AutoPrefix

      def length
	return self[:size1], self[:size2], self[:tda]
      end

      # TODO: needs work
      def values
	r,c,t = length

	alldata = self[:data].get_array_of_double(0, (t*c))

	allvalues = []
	
	(0..r-1).each { |i|
	  allvalues << alldata[(t*i),c]
	}

	return allvalues
      end

=begin
      def length
	return self[:size]
      end

      def values
	return self[:data].get_array_of_double(0,length)
      end

      def set_with_array( a )
	self[:data].put_array_of_double(0,a)
      end
      def minmax
	min = ::FFI::MemoryPointer.new :double
	max = ::FFI::MemoryPointer.new :double

	::GSL4r::Vector::Methods::gsl_vector_minmax( self, min, max )

	rmin = min.get_double(0)
	rmax = max.get_double(0)
	min = nil
	max = nil

	return rmin, rmax
      end

      def minmax_index
	min = ::FFI::MemoryPointer.new :size_t
	max = ::FFI::MemoryPointer.new :size_t

	::GSL4r::Vector::Methods::gsl_vector_minmax_index( self, min, max )

	# TODO: Submit request that get_size_t be added to FFI?
	if min.size > FFI::type_size( :ulong )
	  raise RuntimeError, "unsigned long < size_t on this platform!"
	end

	rmin = min.get_ulong(0)
	rmax = max.get_ulong(0)
	min = nil
	max = nil

	return rmin, rmax
      end
=end

      # Play nice and have these methods show up in case someone
      # is digging around for them using these reflection routines
      # Note: this won't show the shortened named forms that
      # will automatically be generated when called.
      def methods
	a = super
	a + GSL_MODULE::Methods.methods.grep(/^#{GSL_PREFIX}/)
      end
      
    end # class GSL_Matrix_Cast

    module Methods
      extend ::GSL4r::Util
      extend ::FFI::Library

      ffi_lib ::GSL4r::GSL_LIB_PATH

      # Utility routines related to handling matrices
      #
      # Creating matrices
      attach_function :gsl_matrix_alloc, [:size_t,:size_t], :pointer
      attach_function :gsl_matrix_calloc, [:size_t,:size_t], :pointer
      attach_function :gsl_matrix_free, [:pointer], :void

      # Accessors
      attach_function :gsl_matrix_get, [:pointer, :size_t, :size_t], :double
      attach_function :gsl_matrix_set, [:pointer, :size_t, :size_t], :double

      # Initializers
      attach_gsl_function :gsl_matrix_set_all, [:pointer, :double], :void
      attach_gsl_function :gsl_matrix_set_zero, [:pointer], :void
      attach_gsl_function :gsl_matrix_set_identity, [:pointer], :void
      
      # Matrix views
      attach_gsl_function :gsl_matrix_submatrix,
	[:pointer, :size_t, :size_t, :size_t, :size_t],
	GSL_Matrix_Cast.by_value

      attach_function :gsl_matrix_view_array, [:pointer, :size_t, :size_t],
	GSL_Matrix_Cast.by_value

      attach_function :gsl_matrix_view_array_with_tda,
	[:pointer, :size_t, :size_t, :size_t],
	GSL_Matrix_Cast.by_value

      attach_function :gsl_matrix_view_vector, [:pointer, :size_t, :size_t],
	GSL_Matrix_Cast.by_value

      attach_function :gsl_matrix_view_vector_with_tda,
	[:pointer, :size_t, :size_t, :size_t],
	GSL_Matrix_Cast.by_value

      attach_gsl_function :gsl_matrix_row,
	[:pointer, :size_t],
	::GSL4r::Vector::GSL_Vector_Cast.by_value

      attach_gsl_function :gsl_matrix_column,
	[:pointer, :size_t],
	::GSL4r::Vector::GSL_Vector_Cast.by_value

    end

    class Harness
      include ::GSL4r::Harness

      def initialize
	@c_compiler = "gcc"
	@c_src_name = "gsl_matrix_tests_gen.c"
	@c_binary = "gsl_matrix_tests_gen"
	@c_includes = ["gsl/gsl_matrix.h"]
	@c_flags = [`gsl-config --libs`.chomp,`gsl-config --cflags`.chomp]
	@c_tests = ::GSL4r::Matrix::Methods.methods.grep(/^c_test/)
	@r_header = %Q{$: << File.join('..','lib')\\nrequire 'test/unit'\\nrequire 'test/unit/autorunner'\\nrequire 'gsl4r/matrix'\\ninclude GSL4r::Matrix\\nclass MatrixTests < Test::Unit::TestCase\\n  EPSILON = 5.0e-15}

	@r_footer = %Q{end}
      end
    end

  end # module Matrix
end # module GSL4r
