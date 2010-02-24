#
# == Other Info
#
# Author::	Colby Gutierrez-Kraybill
# Version::	$Id$
#

require 'rubygems'
require 'monitor'
require 'ffi'

require 'gsl4r/util'
require 'gsl4r/harness'

module GSL4r
  module Complex
    extend ::FFI::Library
    # Note, according to 
    # gnu.org/software/gsl/manual/html_node/Representation-of-complex-numbers.html
    # the layout of the complex numbers struct is supposed to be platform
    # dependent and opaque to applications using GSL.  It also provides
    # C Macros to help with this opaqueness.  Unfortunately, we don't have
    # the luxury of using the macros, nor making the struct mapping opaque.
    # Happily, in practice, on Linux 32 and 64bit, OSX 32 and 64 bit, and
    # Solaris 64 bit, the struct appears to be identical.
    # TODO: Need to check other platforms...
    # TODO: Perhaps integrate use of FFI::Generator to auto-gen the layout
    # for structs, based on the platform this package is installed onto?
    #
    # Note, long double is not implemented, as its size is dependent on
    # the platform.  GCC on intel turns long double into the native
    # 80-bit float of the x86 architecture.  Microsoft VC aliases it
    # back to double.  It would be nice if we could guarantee that it
    # was a 128 quadruple precision value, but... no.

    class GSL_Complex < ::FFI::Struct
      layout :dat, [:double, 2]

      $globalGSLComplexLock = Monitor.new

      EPSILON = 5.0e-15
      R = 0
      I = 1

      #def initialize( a )
	#super()
	#self[:dat][R] = a[:dat][R]
	#self[:dat][I] = a[:dat][I]
      #end
      #def initialize( r, i )
	#super()
	#self[:dat][R] = r
	#self[:dat][I] = i
      #end
      # Create a factory method, as the initialize functions have some
      # issues when copies are created, probably in by_value specifically
      # TODO: followup with Wayne Meissner to confirm this
      class << self
	#
	def create( r=0.0, i=0.0 )
	  myComplex = GSL_Complex.new
	  myComplex.set( r, i )
	end

	# the r_ and c_ methods are designed to help automate the building
	# of tests and not for use in general
	def r_type()
	  "GSL_Complex"
	end

	def r_equals(v1,v2)
	  "#{v1.to_s}.equals(#{v2.to_s})"
	end

	def r_assignment( name )
	  "#{name}.set(2.0,2.0)" # these numbers should make c_assignment for the test
	end

	def c_to_r_assignment(v1,v2)
	  "printf(\\\"  #{v1}.set(%.15g,%.15g)\\\\n\\\",GSL_REAL(#{v2}),GSL_IMAG(#{v2}));\\n"
	end

	def c_type()
	  "gsl_complex"
	end

	def c_assignment( name )
	  "GSL_SET_COMPLEX(&#{name}, 2.0, 2.0);"
	end

	def c_equals()
	end

	def c_value_initializer( name )
	  return "gsl_complex #{name}; " + c_assignment( name )
	end

	def c_pointer_initializer( name )
	  return ""
	end
      end

      # Play nice and have these methods show up in case someone
      # is digging around for them using these reflection routines
      # Note: this won't show the shortened named forms that
      # will automatically be generated when called.
      def methods
	a = super
	a + ::GSL4r::Complex::Methods.methods.grep(/^gsl_complex_/)
      end

      def public_methods
	a = super
	a + ::GSL4r::Complex::Methods.methods.grep(/^gsl_complex_/)
      end

      def real()
	return self[:dat][R]
      end

      def imag()
	return self[:dat][I]
      end

      def equals( a )
	return ( (a[:dat][R] - self[:dat][R]).abs < EPSILON &&
		(a[:dat][I] - self[:dat][I]).abs < EPSILON )
      end

      def set( r, i )
	self[:dat][R] = r
	self[:dat][I] = i
	return self
      end

      def set_real( r )
	self[:dat][R] = r
      end

      def set_imag( i )
	self[:dat][I] = i
      end

      def to_s()
	return "(#{self[:dat][R]},#{self[:dat][I]})"
      end


      # This traps method calls intended to create shortened versions
      # of the GSL function calls.
      # 
      # This first checks if the called method matches the Module
      # function call gsl_complex_#{called_method} (where called_method
      # might be 'abs').
      #
      # If it finds a match (respond_to), it will then create a new
      # method for the class as a whole (class_eval), making the method
      # available to not just this instance of the class, but all
      # existing instances and all those created after.
      # 
      # Finally, the creation is wrapped up in a synchronized call
      # to ensure thread safety.  It is only unsafe the first time
      # the method is invoked (and non-existent at that point).  Every
      # time the method is invoked after, it should not hit method_missing.
      # TODO: Is this true for java threads too, or is it per 'vm' per
      # thread?
      def method_missing( called_method, *args, &block )

	$globalGSLComplexLock.synchronize do

	  prefix = "gsl_complex_"

	  if ( ::GSL4r::Complex::Methods.respond_to?("#{prefix}#{called_method}") == false )
	    prefix = ""
	    if ( ::GSL4r::Complex::Methods.respond_to?("#{called_method}") == false )
	      super # NoMethodError
	    end
	  end

	  self.class.class_eval <<-end_eval
	  def #{called_method}(*args, &block)
	    args.insert(0, self)
	    ::GSL4r::Complex::Methods::#{prefix}#{called_method}( *args, &block )
	  end
	  end_eval

	  __send__(called_method, *args, &block)
	end # globalGSLComplexLock.synchronize
      end # method_missing
    end # GSL_Complex


    class Harness
      include ::GSL4r::Harness

      def initialize
	@c_compiler = "gcc"
	@c_src_name = "gsl_complex_tests_gen.c"
	@c_binary = "gsl_complex_tests_gen"
	@c_includes = ["gsl/gsl_complex.h","gsl/gsl_complex_math.h"]
	@c_flags = [`gsl-config --libs`.chomp,`gsl-config --cflags`.chomp]
	@c_tests = ::GSL4r::Complex::Methods.methods.grep(/^c_test/)
	@r_header = %Q{$: << File.join('..','lib')\\nrequire 'test/unit'\\nrequire 'test/unit/autorunner'\\nrequire 'gsl4r/complex'\\ninclude GSL4r::Complex\\nclass ComplexTests < Test::Unit::TestCase\\n  EPSILON = 5.0e-15}

	@r_footer = %Q{end}

      end # Complex::Harness
    end

    class GSL_Complex_float < GSL_Complex
      layout :dat, [:float, 2]
    end

    # Make namespaces cleaner by putting the attached functions in their
    # own sub-name space
    module Methods 

      # provides attach_gsl_function
      extend ::GSL4r::Util

      extend ::FFI::Library

      ffi_lib GSL4r::GSL_LIB_PATH

      # Returns the argument of the complex number z, arg(z), where -pi < arg(z) <= pi
      attach_gsl_function :gsl_complex_arg, [ GSL_Complex.by_value ], :double,
	[GSL_Complex], :double

      # Returns the magnitude of the complex number z, |z|.
      attach_gsl_function :gsl_complex_abs, [ GSL_Complex.by_value ], :double,
	[GSL_Complex], :double

      # Returns the squared magnitude of the complex number z, |z|^2
      attach_gsl_function :gsl_complex_abs2, [ GSL_Complex.by_value ], :double,
	[GSL_Complex], :double

      # Returns the 
      # the natural logarithm of the magnitude of the complex number z, log|z|.
      # It allows an accurate evaluation of log|z| when |z| is close to one.
      # The direct evaluation of log(gsl_complex_abs(z)) would lead to a loss
      # of precision in this case
      attach_gsl_function :gsl_complex_logabs, [ GSL_Complex.by_value ], :double

      # 5.3 Arithmetic operators

      # Returns the sum of the complex numbers a and b, z=a+b
      attach_gsl_function :gsl_complex_add, Array.new(2, GSL_Complex.by_value),
	GSL_Complex.by_value, Array.new(2, GSL_Complex), GSL_Complex

      # Returns the difference of the complex numbers a and b, z=a-b
      attach_gsl_function :gsl_complex_sub, Array.new(2, GSL_Complex.by_value),
	GSL_Complex.by_value, Array.new(2, GSL_Complex), GSL_Complex

      # Returns the product of the complex numbers a and b, z=ab
      attach_gsl_function :gsl_complex_mul, Array.new(2, GSL_Complex.by_value),
	GSL_Complex.by_value, Array.new(2, GSL_Complex), GSL_Complex

      # Returns the quotient of the complex numbers a and b, z=a/b
      attach_gsl_function :gsl_complex_div, Array.new(2, GSL_Complex.by_value),
	GSL_Complex.by_value, Array.new(2, GSL_Complex), GSL_Complex

      # Returns the sum of the complex number a and the real number x, z=a+x
      attach_gsl_function :gsl_complex_add_real, [ GSL_Complex.by_value, :double ],
	GSL_Complex.by_value, [ GSL_Complex, :double], GSL_Complex

      # Returns the difference of the complex number a and the real number x, z=a-x
      attach_gsl_function :gsl_complex_sub_real, [ GSL_Complex.by_value, :double ],
	GSL_Complex.by_value, [ GSL_Complex, :double], GSL_Complex

      # Returns the product of the complex number a and the real number x, z=ax
      attach_gsl_function :gsl_complex_mul_real, [ GSL_Complex.by_value, :double ],
	GSL_Complex.by_value, [ GSL_Complex, :double], GSL_Complex

      # Returns the quotient of the complex number a and the real number x, z=a/x
      attach_gsl_function :gsl_complex_div_real, [ GSL_Complex.by_value, :double ],
	GSL_Complex.by_value, [ GSL_Complex, :double], GSL_Complex

      # Returns the sum of the complex number a and the imaginary number iy, z=a+iy
      attach_gsl_function :gsl_complex_add_imag, [ GSL_Complex.by_value, :double ],
	GSL_Complex.by_value, [ GSL_Complex, :double], GSL_Complex

      # Returns the difference of the complex number a and the imaginary number iy, z=a-iy
      attach_gsl_function :gsl_complex_sub_imag, [ GSL_Complex.by_value, :double ],
	GSL_Complex.by_value, [ GSL_Complex, :double], GSL_Complex

      # Returns the product of the complex number a and the imaginary number iy, z=a*iy
      attach_gsl_function :gsl_complex_mul_imag, [ GSL_Complex.by_value, :double ],
	GSL_Complex.by_value, [ GSL_Complex, :double], GSL_Complex

      # Returns the quotient of the complex number a and the imaginary number iy, z=a/iy
      attach_gsl_function :gsl_complex_div_imag, [ GSL_Complex.by_value, :double ],
	GSL_Complex.by_value, [ GSL_Complex, :double], GSL_Complex

      # Returns the complex conjugate of the complex number z, z^* = x-iy
      attach_gsl_function :gsl_complex_conjugate, [ GSL_Complex.by_value ],
	GSL_Complex.by_value, GSL_Complex, GSL_Complex

      # Returns the inverse, or reciprocal, of the complex number z, 1/z = (x-iy)/(x^2 + y^2)
      attach_gsl_function :gsl_complex_inverse, [ GSL_Complex.by_value ],
	GSL_Complex.by_value, GSL_Complex, GSL_Complex

      # Returns the negative of the complex number z, -z = (-x) + i(-y)
      attach_gsl_function :gsl_complex_negative, [ GSL_Complex.by_value ],
	GSL_Complex.by_value, GSL_Complex, GSL_Complex

      # 5.4 Elementary Complex Functions
      
      # This function returns the square root of the complex number z, √z.
      # The branch cut is the negative real axis. The result always lies
      # in the right half of the complex plane.
      attach_gsl_function :gsl_complex_sqrt, [ GSL_Complex.by_value ],
	GSL_Complex.by_value, GSL_Complex, GSL_Complex


      # This function returns the complex square root of the real number x,
      # where x may be negative.
      attach_gsl_function :gsl_complex_sqrt_real, [ :double ],
	GSL_Complex.by_value, :double, GSL_Complex


    end
  end
end
