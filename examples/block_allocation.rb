require 'rubygems'
require 'gsl4r'
require 'gsl4r/block'
include FFI
op1 = MemoryPointer.new :pointer
op1 = GSL4r::Block::Methods::gsl_block_alloc(50)
puts op1.get_ulong(0)
ob1=GSL4r::Block::GSL_Block.new(op1)
ob2=GSL4r::Block::GSL_Block_Cast.new(op1)
#puts ob1.length
#op1.put_array_of_double(1, (1..50).to_a.collect { |i| i=i*5.0 } )
#ob1[:data].put_array_of_double(0, (1..50).to_a.collect { |i| i=i*5.0 } )
puts ob2.set( (1..50).to_a.collect { |i| i=i*5.0 } )
v = ob2.values
v[1] = 3000.0
puts v
