
#
# == Other Info
#
# Author::	Colby Gutierrez-Kraybill
# Version::	$Id$
#

require 'rubygems'
require 'ffi'

module GSL4r
  Version = '0.0.1';
  GSL_LIB_PATH = File.join([`gsl-config --prefix`.chomp,
			   "lib","libgsl.#{FFI::Platform::LIBSUFFIX}"])
  GSLCBLAS_LIB_PATH = File.join([`gsl-config --prefix`.chomp,
			   "lib","libgslcblas.#{FFI::Platform::LIBSUFFIX}"])
end
