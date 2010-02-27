
#
# == Other Info
#
# Author::      Colby Gutierrez-Kraybill
# Version::     $Id$
#

require 'rubygems'

module GSL4r
  module Harness
    attr_accessor :c_includes, :c_libs, :c_tests, :c_src_name, :c_binary
    attr_accessor :r_header, :r_footer

    TEST_DIR = "test"

    def write_c_tests
      f = File.new("#{TEST_DIR}/#{@c_src_name}", "w")
      f.puts "/* Auto generated by #{self.class.name} */"
      f.puts "#include <stdio.h>"
      @c_includes.each { |i|
	f.puts "#include \"#{i}\""
      }
      f.puts "int main( int argc, char **argv )\n{\n"
      
      f.puts "  puts(\"#{@r_header}\");"

      @c_tests.each { |t|
	t_fqmn_a = self.class.name.split("::")
	t_fqmn_a.pop
	src = ""
	eval <<-end_eval
	   src = ::#{t_fqmn_a.join("::")}::Methods::#{t}
	end_eval
	f.puts " /* #{t} */"
	f.puts src
      }

      f.puts "  puts(\"#{@r_footer}\");"

      f.puts "  return(0);\n}\n"
      f.close
    end

    def compile_c_tests
      compile_s = "#{@c_compiler} #{@c_flags.join(" ")} " +
	"-o #{TEST_DIR}/#{@c_binary} #{TEST_DIR}/#{@c_src_name}"
      p compile_s
      `#{compile_s}`
    end

    def run_c_tests( filename )
      `#{TEST_DIR}/#{@c_binary} > test/#{filename}`
    end

  end
end
