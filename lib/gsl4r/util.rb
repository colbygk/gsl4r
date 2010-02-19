
#
# == Other Info
#
# Author::      Colby Gutierrez-Kraybill
# Version::     $Id$
#

require 'rubygems'

module GSL4r
  module Util

    $c_var_num = 0

    def attach_gsl_function( method_name, args, return_var, args_type=nil, return_type=nil )

      # This function is attached to the extended ::FFI::Library
      # module from the calling namespace, e.g. ::GSL4r::Complex::Methods
      attach_function method_name, args, return_var

      if ( args_type != nil )
        # prepare c args code
	c_src = ""
	c_call_vars = []
	c_return_name = "c_r#{$c_var_num}"
        args_type.each { |a_t|
	  c_var_name = "v#{$c_var_num += 1}"
	  c_src << (a_t.respond_to?("c_type") ?
		    "  #{a_t.c_type} #{c_var_name};\n" : "#{a_t.to_s} #{c_var_name} ")
	  c_src << (a_t.respond_to?("c_assignment") ?
		    "  #{a_t.c_assignment("#{c_var_name}")}\n" : "= (#{a_t.to_s})1.0;\n")
	  c_call_vars << "#{c_var_name}"
	} # args_type.each

	# prepare c return type
	c_src << (return_type.respond_to?("c_type") ?
		  "  #{return_type.c_type} #{c_return_name};\n" :
		  "  #{return_type.to_s} #{c_return_name};\n")

	# prepare c call
	c_src << "  #{c_return_name} = #{method_name}(#{c_call_vars.join(",")});\n"
	
	# now generate the ruby code for the unit test
	c_src << "  puts(" << %Q{\\"def test_#{method_name}()\\"} << ");\n"
	c_src << "  puts("
	c_src << %Q{\\"  r_r1 = #{method_name}(#{c_call_vars.join(",")})\\"} << ");\n"
	if ( return_type.respond_to?("c_to_r_assignment") )
	  c_src << "  puts(" << %Q{\\"  r_r2 = #{return_type.r_type}.new\\"} << ");\n"
	  c_src << "  puts(" << %Q{\\"  ::#{return_type}.c_to_r_assignment(r_r2,#{c_return_name}\\"} << ");\n"
	  c_src << "  printf(" << %Q{\\"  assert #{return_type.to_s}.r_equals(r_r1,r_r2)\\\\n\\"} << ");\n"
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
    end
  end
end
