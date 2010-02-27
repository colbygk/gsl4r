
#
# == Other Info
#
# Author::	Colby Gutierrez-Kraybill
# Version::	$Id$
#

require 'rubygems'
require 'ffi'

module GSL4r
  module Vector

    extend ::FFI::Library

    ffi_lib ::GSL4r::GSL_LIB_PATH

    class GSL_Vector < ::FFI::Struct
      layout :size,	:size_t,
	:stride,	:size_t,
	:data,	:pointer,
	:block,	:pointer,
	:owner,	:int

      include ::GSL4r::Util::AutoPrefix
      module ::GSL4r::Util::AutoPrefix
	GSL_PREFIX = "gsl_vector_"
	GSL_MODULE = ::GSL4r::Vector
      end

    end # class GSL_Vector
  end # module Vector
end # module GSL4r
