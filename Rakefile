
# $Id$

require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
require 'fileutils'
require 'test/unit'

GEM = "gsl4r"
GEM_VERSION = File.open("VERSION").gets.chomp
AUTHOR = "Colby Gutierrez-Kraybill"
EMAIL = "colby@astro.berkeley.edu"
HOMEPAGE = %q{http://gsl4r.rubyforge.org}
SUMMARY = "GSL4r, ruby FFI wrappers around GNU Scientific Library"
DESCRIPTION = "Wrappers around the GNU Scientific Library using Foreign Function Interface.  This allows all ruby implementations that support FFI to interface to the C based GSL routines."
DIRS = [ "lib/**/*", "test/**/*" ]

gsl_cflags = ""
gsl_ldflags = ""
gsl_lib_path = ""


spec = Gem::Specification.new do |s|
  s.name = GEM
  s.rubyforge_project = s.name
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE", 'TODO', 'changelog']
  s.summary = SUMMARY
  s.description = DESCRIPTION
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE

  s.requirements << 'GNU Scientific Library, version 1.13 or greater'
  s.require_path = 'lib'
  s.files = %w{LICENSE LICENSE.LGPLv3 README INSTALL Rakefile TODO changelog}
  s.files = s.files + DIRS.collect do |dir|
    Dir.glob( dir )
  end.flatten.delete_if { |f| f.include?(".git") }
end

Rake::GemPackageTask.new(spec) do |pkg|
end

desc "install the gem locally"
task :install => [:package] do
  sh %{gem install pkg/#{GEM}-#{GEM_VERSION}}
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{GEM}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

task :test => [:gsl_config] do
  $: << 'lib'

  require 'gsl4r'
  require 'gsl4r/complex'
  require 'gsl4r/vector'

  complextests = GSL4r::Complex::Harness.new
  complextests.write_c_tests
  complextests.compile_c_tests
  complextests.run_c_tests "complex_test.rb"

  vectortests = GSL4r::Vector::Harness.new
  vectortests.write_c_tests
  vectortests.compile_c_tests
  vectortests.run_c_tests "vector_test.rb"

  runner = Test::Unit::AutoRunner.new(true)
  runner.to_run << 'test'
  runner.pattern = [/_test.rb$/]
  exit if !runner.run
end

task :gsl_config do
  gsl_cflags = `gsl-config --cflags`.chomp
  if ( $?.to_i != 0 )
    raise "Unable to run 'gsl-config', is it in the PATH? It doesn't support --cflags?"
  end

  gsl_ldflags = `gsl-config --libs`.chomp
  if ( $?.to_i != 0 )
    raise "Unable to run 'gsl-config', it doesn't support --libs?"
  end

  gsl_lib_path = File.join(`gsl-config --prefix`.chomp, "lib")
  if ( $?.to_i != 0 )
    raise "Unable to run 'gsl-config', it doesn't support --prefix?"
  end

  ENV["CFLAGS"] = (ENV.has_key?("CFLAGS") ? ENV["CFLAGS"]+" " : gsl_cflags)
  ENV["LDFLAGS"] = (ENV.has_key?("LDFLAGS") ? ENV["LDFLAGS"]+" " : gsl_ldflags)
  ENV['LD_LIBRARY_PATH'] = (ENV.has_key?('LD_LIBRARY_PATH') ?
			    ENV['LD_LIBRARY_PATH']+":"+gsl_lib_path : gsl_lib_path)
end

task :default => [:gsl_config,:package] do
end
