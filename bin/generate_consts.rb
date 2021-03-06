#!/usr/bin/env ruby

# This program generates constant expressions based on input from the GSL
# physical constant related headers.
# This program keys off the C macro expressions for #define, so the raw
# header file is acceptable as input.
# i.e.
#   /opt/local/include/gsl/gsl_const_mksa.h 

if ARGV.length < 1 
  raise %Q{Must pass in at least one filename, file must have list of functions}
end

# Split prototype into method name, arguments, return type and comment section
def split_macro( macro )
  crap,pdefine,fqn,val,comment = macro.split(/^(#define)\s+(\w+)\s+\((.+)\)\s+(\/\*.*)/)
  crap,crap,module_name,const_name = fqn.split(/^(GSL_CONST)_+([^_]+)_+(\w*)/)
  return module_name, const_name, val, "#{comment}".gsub("\*\/","")
end

ARGV.each do |file|
  File.open(file, "r") do |infile|
    puts "# Generated by gsl4r/bin/generate_consts.rb"
    puts "# from #{file}"
    puts "module GSL4r"
    puts "  module PhysicalConstants"
    curr_name = ""
    all_names = []
    while line = infile.gets
      if ( line =~ /^#define/ && line !~ /__GSL_/)

	module_name, const_name, val, comment = split_macro( line.chomp )

	if ( curr_name != module_name )
	  if ( curr_name != "" )
	    puts "end"
	  end
	  puts "    module #{module_name}"
	  curr_name = module_name
	end

	puts "      #{const_name} = (#{val}) # #{comment.gsub(/\/\*/,'')}"
	all_names << const_name

      end
    end
    puts "      def all_names"
    puts "        return [\"#{all_names.join("\",\"")}\"]"
    puts "      end"
    if ( curr_name != "" )
      puts "    end"
    end
    puts "  end"
    puts "end"
  end
end



