
#
# == Other Info
#
# Author::      Colby Gutierrez-Kraybill
# Version::     $Id$
#

require 'rubygems'

module GSL4r
  module Util
    def attach_gsl_function( method_name, args, return_var, args_type=nil, return_type=nil )

      # This function is attached to the extended ::FFI::Library
      # module from the calling namespace, e.g. ::GSL4r::Complex::Methods
      attach_function method_name, args, return_var

      if ( args_type != nil )
        # prepare c args code
	c_src = ""
	c_var_num = 0
	c_call_vars = []
        args_type.each { |a_t|
	  c_var_name = "v#{c_var_num += 1}"
	  c_src << (a_t.respond_to?("c_type") ?
		    "#{a_t.c_type} #{c_var_name};\n" : "#{a_t.to_s} #{c_var_name} ")
	  c_src << (a_t.respond_to?("c_assignment") ?
		    "#{a_t.c_assignment("#{c_var_name}")}\n" : "= (#{a_t.to_s})1.0;\n")
	  c_call_vars << "#{c_var_name}"
	} # args_type.each

	# prepare c return type
	c_src << (return_type.respond_to?("c_type") ?
		  "#{return_type.c_type} c_r1;\n" : "#{return_type.to_s} c_r1;\n")

	# prepare c call
	c_src << "c_r1 = #{method_name}(#{c_call_vars.join(",")});\n"
	
	# now generate the ruby code for the unit test
	c_src << "puts(" << %Q{\\"def test_#{method_name}()\\"} << ");\n"
	c_src << "puts("
	c_src << %Q{\\"  r_r1 = #{method_name}(#{c_call_vars.join(",")})\\"} << ");\n"
	c_src << "printf(" << %Q{\\"  assert_in_delta r_r1, %g, EPSILON\\\\n\\"} << ", c_r1);\n"
	c_src << "puts(" << %Q{\\"end\\"} << ");"


	eval <<-end_eval
        def c_test_#{method_name}
  	  # Build list of arguments and their values
#	  c_src = c_src + " #{return_var.to_s} a = #{method_name}(#{args.class});" 
	  "#{c_src}"
        end
	end_eval
      end
#        p "printf(\" assert_in_delta method_name\")"
    end
  end
end
