
#
# == Other Info
#
# Author::      Colby Gutierrez-Kraybill
# Version::     $Id$
#

require 'rubygems'
require 'monitor'

module GSL4r
  module Util

    $c_var_num = 0

    # TODO: The automated test writing is kindof klunky and probably
    # ought to be re-thought out...
    def attach_gsl_function( method_name, args, return_var, args_type=nil, return_type=nil,
			    add_self=true, answerat=0 )

      # This function is attached to the extended ::FFI::Library
      # module from the calling namespace, e.g. ::GSL4r::Complex::Methods
      attach_function method_name, args, return_var

      # Give a hint to the current module if this method should add a copy
      # of itself to the calling list to make calls convienent e.g. a.abs
      self.class.class_eval <<-end_eval
        ::#{self}::#{method_name.to_s.upcase}_ADD_SELF = #{add_self}
      end_eval

      if ( args_type != nil )
        # prepare c and ruby args code
	c_src = ""
	c_call_vars = []

	c_return_name = ( answerat == 0 ? "c_r#{$c_var_num}" : "" )

	r_src = []
	if ( ! args_type.is_a?(Array) )
	  args_type = Array.new([args_type])
	end
        args_type.each { |a_t|
	  c_var_name = "v#{$c_var_num += 1}"

	  # This tracks if the answer to check against is in a variable
	  # *other than* the return value.  For example:
	  # sprintf( char *ans, char *format, ... ), the answer is
	  # in *ans (aka 1).  answerat == 0 is the return value
	  if ( answerat == $c_var_num )
	    c_return_name = c_var_name
	  end

	  c_src << (a_t.respond_to?("c_type") ?
		    "  #{a_t.c_type} #{c_var_name};\n" : "#{a_t.to_s} #{c_var_name} ")
	  c_src << (a_t.respond_to?("c_initializer") ?
		    "  #{a_t.c_initializer("#{c_var_name}")}\n" : "")
	  c_src << (a_t.respond_to?("c_assignment") ?
		    "  #{a_t.c_assignment("#{c_var_name}")}\n" : "= (#{a_t.to_s})2.0;\n")
	  c_call_vars << "#{c_var_name}"

	  r_src << (a_t.respond_to?("r_initializer") ?
		    "  #{c_var_name} = #{a_t.r_initializer}" : "")
	  r_src << (a_t.respond_to?("r_assignment") ?
		    "  #{a_t.r_assignment("#{c_var_name}")}" : "  #{c_var_name} = 2.0")
	} # args_type.each

	# prepare c return type
	# if the answer is coming back not from the return value,
	# then don't bother adding this
	if ( answerat == 0 )
	  c_src << (return_type.respond_to?("c_type") ?
		    "  #{return_type.c_type} #{c_return_name};\n" :
		    "  #{return_type.to_s} #{c_return_name};\n")
	  c_src << "  #{c_return_name} = "
	else
	  c_src << "  "
	end

	# prepare c call
	
	c_src << "#{method_name}(#{c_call_vars.join(",")});\n"
	
	# now generate the ruby code for the unit test
	c_src << "  puts(" << %Q{\\"def test_#{method_name}()\\"} << ");\n"

	# TODO, Need to insert ruby object instantiation code here!
	#
	r_src.each { |v|
	  c_src << "  puts(" << %Q{\\"#{v}\\"} << ");\n"
	}

	r_r1 = "r_r1" # ruby result
	c_src << "  puts(" << %Q{\\"  #{r_r1} = ::#{self.to_s}::#{method_name}(#{c_call_vars.join(",")})\\"} << ");\n"
	if ( answerat == 0 )
	  if ( return_type.respond_to?("c_to_r_assignment") )
	    r_r2 = "r_r2" # ruby result comparitor
	    c_src << "  puts(" << %Q{\\"  #{r_r2} = #{return_type.r_type}.new\\"} << ");\n"
	    c_src << "  #{return_type.c_to_r_assignment(r_r2,c_return_name)}"
	    c_src << "  printf(" << %Q{\\"  assert r_r1.equals(r_r2)\\\\n\\"} << ");\n"
	  else # return_type.respond_to
	    # TODO: this will have to be expanded to handle more types..
	    # A good default fall back is unsigned long though, for size_t or int returns
	    # but this could lead to submit errors that aren't really errors...
	    c_src << "  printf(" << %Q{\\"  assert_in_delta r_r1, #{(return_type == :double ? "%.15g" : "%lu")}, EPSILON\\\\n\\"} << ", #{c_return_name});\n"
	  end
	else # answerat == 0
	  c_src << "  printf(" << %Q{\\"  assert }
	  # I'd rather this fail at run-time so, don't check if r_answer is there
	  c_src << args_type[answerat-1].r_answer("#{c_call_vars[answerat-1]}")
	  c_src << args_type[answerat-1].r_equals << %Q{\\");\n}
	  c_src << "  " << args_type[answerat-1].c_answer("#{c_call_vars[answerat-1]}")
	end

	c_src << "  puts(" << %Q{\\"end\\"} << ");"

	# TODO, create unit test for aliased/shorthand versions of methods
 
	self.module_eval <<-end_eval
	  def c_test_#{method_name}
  	    # Build list of arguments and their values
	    "#{c_src}"
          end
	  module_function :c_test_#{method_name}
	end_eval
      end
    end # attach_gsl_function

    module AutoPrefix 

      $prefixLock = Monitor.new

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

	$prefixLock.synchronize do

	  prefix = self.class::GSL_PREFIX

	  if ( self.class::GSL_MODULE::Methods.respond_to?("#{prefix}#{called_method}") == false )
	    prefix = ""
	    if ( self.class::GSL_MODULE::Methods.respond_to?("#{called_method}") == false )
	      super # NoMethodError
	    end
	  end

	  # TODO: this could be smoothed out with the #args/#parameters parts of
	  # Ruby 1.9.
	  # This could inspect the definition of the parameter and if the
	  # first argument in the definition were of the same type as self
	  # then self could be inserted into the args list per below
	  # rather than requiring the #{called_method.to_s.upcase}_ADD_SELF
	  # boolean definition and check
	  self.class.class_eval <<-end_eval
	  def #{called_method}(*args, &block)
	    if ::#{self.class::GSL_MODULE.to_s}::Methods::#{prefix.to_s.upcase}#{called_method.to_s.upcase}_ADD_SELF 
	      args.insert(0, self)
	    end
	    ::#{self.class::GSL_MODULE.to_s}::Methods::#{prefix}#{called_method}( *args, &block )
	  end
	  end_eval

	  __send__(called_method, *args, &block)
	end # prefixLock.synchronize
      end # method_missing
    end # AutoPrefix

  end # Util
end # GSL4r
