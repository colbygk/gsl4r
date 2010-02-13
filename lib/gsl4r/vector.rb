
#
# == Other Info
#
# Author::	Colby Gutierrez-Kraybill
# Version::	$Id$
#

require 'rubygems'
require 'ffi'

module GSL4r

  extend ::FFI::Library

  ffi_lib 'gsl'

  class Vector
    attach_function :gsl_vector_alloc, [ :size_t ], :pointer
    attach_function :gsl_vector_calloc, [ :size_t ], :pointer
    attach_function :gsl_vector_free, [ :pointer ], :void

    # initializing
    attach_function :gsl_vector_set_all, [ :pointer, :double ], :void
    attach_function :gsl_vector_set_zero, [ :pointer ], :void
    attach_function :gsl_vector_set_basis, [ :pointer, :size_t ], :int
  end

end
