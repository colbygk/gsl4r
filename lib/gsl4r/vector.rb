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

module GSL4r
  module Vector

    extend ::FFI::Library

    # layout/cast/struct pattern /lifted from
    # http://wiki.github.com/ffi/ffi/examples
    module VectorLayout
      def self.included(base)
	base.class_eval do
	  layout :size,	:size_t,
	    :stride,	:size_t,
	    :data,	:pointer,
	    :block,	:pointer,
	    :owner,	:int
	end
      end
    end

    def get_vector_size( a_vector )
      return a_vector.get_ulong(0)
    end
    module_function :get_vector_size

    def get_vector_stride( a_vector )
      return a_vector.get_ulong(1)
    end
    module_function :get_vector_stride

    # TODO fix me
    def get_vector_data( a_vector )
      return a_vector.values
    end
    module_function :get_vector_data

    def set_vector_data( a_block, some_data )
      if ( some_data.length > ::GSL4r::Block::get_block_size(a_block) )
	raise "data exceeds size of block"
      end
      a_block.put_array_of_double(1,some_data)
      return some_data
    end
    module_function :set_vector_data

    class GSL_Vector < FFI::ManagedStruct
      include ::GSL4r::Vector::VectorLayout

      attr_accessor :vecptr

      GSL_PREFIX = "gsl_vector_"
      GSL_MODULE = ::GSL4r::Vector

      include ::GSL4r::Util::AutoPrefix

      def self.create( size )
	@vecptr = ::FFI::MemoryPointer.new :pointer
	@vecptr = ::GSL4r::Vector::Methods::gsl_vector_alloc( size )

	GSL_Vector.new( @vecptr )
      end

      def self.release(ptr)
	::GSL4r::Vector::Methods::gsl_vector_free(ptr)
      end

      def length
	return self[:size]
      end

      def values
	return self[:data].get_array_of_double(0,self.length)
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
	  "GSL_Vector"
	end
	def r_initializer()
	  r_type + ".create(3)"
	end
	def r_equals()
	  " == "
	end
	def r_answer( name )
	  "#{name}.values"
	end
	def r_assignment( name )
	  "#{name}.set( [1.0,2.0,3.0] )" # these numbers should make c_assignment ...
	end
	def c_to_r_assignment(v1,v2)
	  "printf(\\\"  #{v1}.set([%.15g,%.15g,%.15g])\\\\n\\\",gsl_vector_get(#{v2},0),gsl_vector_get(#{v2},1),gsl_vector_get(#{v2},2));\\n"
	end
	def c_type()
	  "gsl_vector *"
	end
	def c_assignment( name )
	  "gsl_vector_set(#{name}, 0, 1.0 ); gsl_vector_set(#{name}, 1, 2.0 ); gsl_vector_set(#{name}, 2, 3.0 );"
	end
	def c_answer( name )
	  "printf(\\\"[%.15g,%.15g,%.15g]\\\\n\\\",gsl_vector_get(#{name},0),gsl_vector_get(#{name},1),gsl_vector_get(#{name},2));\\n"
	end
	def c_equals()
	end
	def c_initializer( name )
	  "#{name} = gsl_vector_alloc(3); "
	end
      end # class << self

    end # GSL_Vector

    class GSL_Vector_Cast < FFI::Struct
      include ::GSL4r::Vector::VectorLayout

      GSL_PREFIX = "gsl_vector_"
      GSL_MODULE = ::GSL4r::Vector

      include ::GSL4r::Util::AutoPrefix

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

      # Play nice and have these methods show up in case someone
      # is digging around for them using these reflection routines
      # Note: this won't show the shortened named forms that
      # will automatically be generated when called.
      def methods
	a = super
	a + GSL_MODULE::Methods.methods.grep(/^#{GSL_PREFIX}/)
      end
      
    end # class GSL_Vector_Cast

    class GSL_Vector_View < FFI::Struct
      layout :vector, GSL_Vector_Cast

      def values
	(0..self[:vector].length-1).to_a.collect { |i|
	  ::GSL4r::Vector::Methods::gsl_vector_get( self[:vector], i )
	}
      end

    end

    module Methods
      extend ::GSL4r::Util
      extend ::FFI::Library

      ffi_lib ::GSL4r::GSL_LIB_PATH

      # Utility routines related to handling vectors
      #
      # Creating vectors
      attach_function :gsl_vector_alloc, [:size_t], :pointer
      attach_function :gsl_vector_calloc, [:size_t], :pointer
      attach_function :gsl_vector_free, [:pointer], :void

      # set/get individual values
      attach_gsl_function :gsl_vector_get, [:pointer, :size_t], :double
      attach_gsl_function :gsl_vector_set, [:pointer, :size_t, :double], :void

      # set values across entire vector
      attach_gsl_function :gsl_vector_set_all, [:pointer, :double], :void
      attach_gsl_function :gsl_vector_set_zero, [:pointer], :void
      attach_gsl_function :gsl_vector_set_basis, [:pointer, :size_t], :int

      # Vector views
      #
      # These return a GSL_Vector_Cast to avoid inappropriate garbage
      # collection on the returned structure
      attach_gsl_function :gsl_vector_subvector, [:pointer, :size_t, :size_t],
	GSL_Vector_Cast.by_value

      attach_gsl_function :gsl_vector_subvector_with_stride,
	[:pointer, :size_t, :size_t, :size_t],
	GSL_Vector_Cast.by_value

      # Copying vectors
      attach_gsl_function :gsl_vector_memcpy, [:pointer, :pointer], :int
      attach_gsl_function :gsl_vector_swap, [:pointer, :pointer], :int

      # Exchanging elements
      attach_gsl_function :gsl_vector_swap_elements, [:pointer, :size_t, :size_t], :int
      attach_gsl_function :gsl_vector_reverse, [:pointer], :int

      # basic arithmetic
      # a'i = ai + bi
      attach_gsl_function :gsl_vector_add, [:pointer, :pointer], :int,
	[GSL_Vector, GSL_Vector], :double, true, 1
      # a'i = ai - bi
      attach_gsl_function :gsl_vector_sub, [:pointer, :pointer], :int,
	[GSL_Vector, GSL_Vector], :double, true, 1
      # a'i = ai * bi
      attach_gsl_function :gsl_vector_mul, [:pointer, :pointer], :int,
	[GSL_Vector, GSL_Vector], :double, true, 1
      # a'i = ai / bi
      attach_gsl_function :gsl_vector_div, [:pointer, :pointer], :int,
	[GSL_Vector, GSL_Vector], :double, true, 1
      # a'i = x * ai
      attach_gsl_function :gsl_vector_scale, [:pointer, :double], :int,
	[GSL_Vector, :double], :double, true, 1
      # a'i = x + ai
      attach_gsl_function :gsl_vector_add_constant, [:pointer, :double], :int,
	[GSL_Vector, :double], :double, true, 1
      # return max value
      attach_gsl_function :gsl_vector_max, [:pointer], :double,
	[GSL_Vector], :double
      # return max value index
      attach_gsl_function :gsl_vector_max_index, [:pointer], :size_t,
	[GSL_Vector], :size_t
      # return min value
      attach_gsl_function :gsl_vector_min, [:pointer], :double,
	[GSL_Vector], :double
      # return min value index
      attach_gsl_function :gsl_vector_min_index, [:pointer], :size_t,
	[GSL_Vector], :size_t

      # minmax routines have special wrappers to make them easier to use
      # return min and max values
      # TODO: increase answer checking sophistication in util to compare
      # results that arrive in mulitple arguments, like minmax...
      attach_function :gsl_vector_minmax, [:pointer, :pointer, :pointer], :void
      attach_function :gsl_vector_minmax_index, [:pointer, :pointer, :pointer], :void

      # Vector properties
      
      # returns 1 if vector is null, 0 otherwise
      attach_gsl_function :gsl_vector_isnull, [:pointer], :int,
	[GSL_Vector], :int
      # returns 1 if vector is all positive, 0 otherwise
      attach_gsl_function :gsl_vector_ispos, [:pointer], :int,
	[GSL_Vector], :int
      # returns 1 if vector is all negative, 0 otherwise
      attach_gsl_function :gsl_vector_isneg, [:pointer], :int,
	[GSL_Vector], :int
      # returns 1 if vector is all non-negative, 0 otherwise
      attach_gsl_function :gsl_vector_isnonneg, [:pointer], :int,
	[GSL_Vector], :int

    end

    class Harness
      include ::GSL4r::Harness

      def initialize
	@c_compiler = "gcc"
	@c_src_name = "gsl_vector_tests_gen.c"
	@c_binary = "gsl_vector_tests_gen"
	@c_includes = ["gsl/gsl_vector.h"]
	@c_flags = [`gsl-config --libs`.chomp,`gsl-config --cflags`.chomp]
	@c_tests = ::GSL4r::Vector::Methods.methods.grep(/^c_test/)
	@r_header = %Q{$: << File.join('..','lib')\\nrequire 'test/unit'\\nrequire 'test/unit/autorunner'\\nrequire 'gsl4r/vector'\\ninclude GSL4r::Vector\\nclass VectorTests < Test::Unit::TestCase\\n  EPSILON = 5.0e-15}

	@r_footer = %Q{end}
      end
    end

  end # module Vector
end # module GSL4r
