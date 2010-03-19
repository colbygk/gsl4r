$: << File.join('..','lib')

require 'rubygems'
require 'gsl4r'
require 'gsl4r/vector'
include FFI

vp1 = MemoryPointer.new :pointer
vp1 = GSL4r::Vector::Methods::gsl_vector_alloc(50)

# Creating object wrapper around pointer
vec1=GSL4r::Vector::GSL_Vector.new(vp1)

puts "vec1.length: #{vec1.length}"

# Creating a 'cast' object around pointer
vec2=GSL4r::Vector::GSL_Vector_Cast.new(vp1)

puts "vec2.length: #{vec2.length}"

# assign values to castable object
vec2.set( (1..50).to_a.collect { |i| i=i*5.0 } )

# get those values and show them
v = vec2.values
printf "vec2.values: "
v.each { |i| printf "%g ", i }

# show that the non-cast object is referencing vp1
z = vec1.values
printf "\nvec1.values: "
z.each { |i| printf "%g ", i }

printf "\n"
