#!/usr/bin/env ruby

# This program generates attach_gsl_function stubs, based on the C prototypes
# The format of the input file should be one, well formed prototype per line
# e.g.
#   gsl_complex gsl_complex_arcsin (gsl_complex a);  /* r=arcsin(a) */

if ARGV.length < 1 
  raise %Q{Must pass in at least one filename, file must have list of functions}
end

class Array
  def type_info
    select { |x| index(x) % 2 == 0 }
  end
end

# Split prototype into method name, arguments, return type and comment section
def split_prototype( prototype )

  # Split apart the prototype into its constituents
  # Someday, may need to do something with a modifier i.e. const
  modifier,return_type,method_name,args,comment =
    prototype.split(/([^\W]+)\s+([^\W]+)\s{0,}(\(.+\));\s{0,}(\/\*.*)/)

  # This will have to be modified to handle modifiers to the type
  # information, pointer * or &reference, or array[]
  argsparsed = args.gsub(/\(|\)/,'').split(/(\w+)(\s{0,})(\w{0,})(,{0,})/)

  # the regex above will place the type information in index(1) of the
  # array, then 5 positions after that for the next one, and so on...
  argtypes = []
  i = 1
  until argsparsed.length <= i
    argtypes << argsparsed[i]
    i += 5
  end

  return method_name, argtypes, return_type, "#{comment}".gsub("\*","")
end

implsubsmap = {
  "gsl_complex" => "GSL_Complex.by_value",
  "double" => ":double"
}

typesubsmap = {
  "gsl_complex" => "GSL_Complex",
  "double" => ":double"
}
  
ARGV.each do |file|
  File.open(file, "r") do |infile|
    while line = infile.gets
      method_name, args, return_type, comment = split_prototype( line.chomp )
      c_return = return_type.gsub(return_type, implsubsmap[return_type])
      r_return = return_type.gsub(return_type, typesubsmap[return_type])
      c_args = "[ "
      r_args = c_args
      args.each do |arg|
	c_args += arg.gsub(arg, implsubsmap[arg]) + ", "
	r_args += arg.gsub(arg, typesubsmap[arg]) + ", "
      end
      c_args = c_args.chop.chop + " ]"
      r_args = r_args.chop.chop + " ]"

      puts "# #{comment}"
      puts "attach_gsl_function :#{method_name}, #{c_args},\n #{c_return}, #{r_args}, #{r_return}"
    end
  end
end



