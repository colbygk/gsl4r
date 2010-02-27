
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

    def attach_gsl_function( method_name, args, return_var, args_type=nil, return_type=nil,
			    add_self=true )

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
	c_return_name = "c_r#{$c_var_num}"
	r_src = []
	if ( ! args_type.is_a?(Array) )
	  args_type = Array.new([args_type])
	end
        args_type.each { |a_t|
	  c_var_name = "v#{$c_var_num += 1}"
	  c_src << (a_t.respond_to?("c_type") ?
		    "  #{a_t.c_type} #{c_var_name};\n" : "#{a_t.to_s} #{c_var_name} ")
	  c_src << (a_t.respond_to?("c_assignment") ?
		    "  #{a_t.c_assignment("#{c_var_name}")}\n" : "= (#{a_t.to_s})2.0;\n")
	  c_call_vars << "#{c_var_name}"

	  r_src << (a_t.respond_to?("r_type") ?
		    "  #{c_var_name} = #{a_t.r_type}.create" : "")
	  r_src << (a_t.respond_to?("r_assignment") ?
		    "  #{a_t.r_assignment("#{c_var_name}")}" : "  #{c_var_name} = 2.0")
	} # args_type.each

	# prepare c return type
	c_src << (return_type.respond_to?("c_type") ?
		  "  #{return_type.c_type} #{c_return_name};\n" :
		  "  #{return_type.to_s} #{c_return_name};\n")

	# prepare c call
	c_src << "  #{c_return_name} = #{method_name}(#{c_call_vars.join(",")});\n"
	
	# now generate the ruby code for the unit test
	c_src << "  puts(" << %Q{\\"def test_#{method_name}()\\"} << ");\n"

	# TODO, Need to insert ruby object instantiation code here!
	#
	r_src.each { |v|
	  c_src << "  puts(" << %Q{\\"#{v}\\"} << ");\n"
	}

	r_r1 = "r_r1" # ruby result
	c_src << "  puts(" << %Q{\\"  #{r_r1} = ::#{self.to_s}::#{method_name}(#{c_call_vars.join(",")})\\"} << ");\n"
	if ( return_type.respond_to?("c_to_r_assignment") )
	  r_r2 = "r_r2" # ruby result comparitor
	  c_src << "  puts(" << %Q{\\"  #{r_r2} = #{return_type.r_type}.new\\"} << ");\n"
	  c_src << "  #{return_type.c_to_r_assignment(r_r2,c_return_name)}"
	  c_src << "  printf(" << %Q{\\"  assert r_r1.equals(r_r2)\\\\n\\"} << ");\n"
	else
	  c_src << "  printf(" << %Q{\\"  assert_in_delta r_r1, %.15g, EPSILON\\\\n\\"} << ", #{c_return_name});\n"
	end

	c_src << "  puts(" << %Q{\\"end\\"} << ");"


	eval <<-end_eval
        def c_test_#{method_name}
  	  # Build list of arguments and their values
	  "#{c_src}"
        end
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

	  prefix = GSL_PREFIX

	  if ( GSL_MODULE::Methods.respond_to?("#{prefix}#{called_method}") == false )
	    prefix = ""
	    if ( GSL_MODULE::Methods.respond_to?("#{called_method}") == false )
	      super # NoMethodError
	    end
	  end

	  self.class.class_eval <<-end_eval
	  def #{called_method}(*args, &block)
	    if ::#{GSL_MODULE.to_s}::Methods::#{prefix.to_s.upcase}#{called_method.to_s.upcase}_ADD_SELF 
	      args.insert(0, self)
	    end
	    ::#{GSL_MODULE.to_s}::Methods::#{prefix}#{called_method}( *args, &block )
	  end
	  end_eval

	  __send__(called_method, *args, &block)
	end # prefixLock.synchronize
      end # method_missing
    end # AutoPrefix

  end # Util
end # GSL4r
