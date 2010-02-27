
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

    ffi_lib 'gsl'

    class GSL_Vector < FFI::Struct
    layout :size,	:size_t,
           :stride,	:size_t,
           :data,	:pointer,
           :block,	:pointer,
           :owner,	:int
    end
  end
end
