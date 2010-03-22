#
# == Other Info
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

      # Play nice and have these methods show up in case someone
      # is digging around for them using these reflection routines
      # Note: this won't show the shortened named forms that
      # will automatically be generated when called.
      def methods
	a = super
	a + GSL_MODULE::Methods.methods.grep(/^#{GSL_PREFIX}/)
      end
      
    end # class GSL_Vector_Cast

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

      # a'i = ai + bi
      attach_gsl_function :gsl_vector_add, [:pointer, :pointer], :int
      # a'i = ai - bi
      attach_gsl_function :gsl_vector_sub, [:pointer, :pointer], :int
      # a'i = ai * bi
      attach_gsl_function :gsl_vector_mul, [:pointer, :pointer], :int
      # a'i = ai / bi
      attach_gsl_function :gsl_vector_div, [:pointer, :pointer], :int
      # a'i = x * ai
      attach_gsl_function :gsl_vector_scale, [:pointer, :double], :int
      # a'i = x + ai
      attach_gsl_function :gsl_vector_add_constant, [:pointer, :double], :int
      # return max value
      attach_gsl_function :gsl_vector_max, [:pointer], :double
      # return max value index
      attach_gsl_function :gsl_vector_max_index, [:pointer], :size_t
      # return min value
      attach_gsl_function :gsl_vector_min, [:pointer], :double
      # return min value index
      attach_gsl_function :gsl_vector_min_index, [:pointer], :size_t

      # minmax routines have special wrappers to make them easier to use
      # return min and max values
      attach_function :gsl_vector_minmax, [:pointer, :pointer, :pointer], :void
      attach_function :gsl_vector_minmax_index, [:pointer, :pointer, :pointer], :void

    end
  end # module Vector
end # module GSL4r
