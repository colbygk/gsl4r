$: << File.join('..','lib')

require 'rubygems'
require 'gsl4r'
require 'gsl4r/block'
include FFI

bp1 = MemoryPointer.new :pointer
bp1 = GSL4r::Block::Methods::gsl_block_alloc(50)

# Creating object wrapper around pointer
blk1=GSL4r::Block::GSL_Block.new(bp1)

puts "blk1.length: #{blk1.length}"

# Creating a 'cast' object around pointer
blk2=GSL4r::Block::GSL_Block_Cast.new(bp1)

puts "blk2.length: #{blk2.length}"

# assign values to castable object
blk2.set( (1..50).to_a.collect { |i| i=i*5.0 } )

# get those values and show them
v = blk2.values
printf "blk2.values: "
v.each { |i| printf "%g ", i }

# show that the non-cast object is referencing bp1
z = blk1.values
printf "\nblk1.values: "
z.each { |i| printf "%g ", i }

printf "\n"
