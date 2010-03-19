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

      GSL_PREFIX = "gsl_vector_"
      GSL_MODULE = ::GSL4r::Vector

      include ::GSL4r::Util::AutoPrefix

      def self.release(ptr)
	::GSL4r::Vector::Methods::gsl_vector_free(ptr)
      end

      def length
	return self[:size]
      end

      def values
	return self[:data].get_array_of_double(0,self.length)
      end

      def set( a )
	self[:data].put_array_of_double(0,a)
	self[:size] = a.length
      end

    end

    class GSL_Vector_Cast < FFI::Struct
      include ::GSL4r::Vector::VectorLayout

      def length
	return self[:size]
      end

      def values
	return self[:data].get_array_of_double(0,length)
      end

      def set( a )
	self[:data].put_array_of_double(0,a)
      end

    end # class GSL_Vector

    module Methods
      extend ::GSL4r::Util
      extend ::FFI::Library

      ffi_lib ::GSL4r::GSL_LIB_PATH

      attach_function :gsl_vector_alloc, [:size_t], :pointer
      attach_function :gsl_vector_calloc, [:size_t], :pointer
      attach_function :gsl_vector_free, [:pointer], :void

    end
  end # module Vector
end # module GSL4r
