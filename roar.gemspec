$:.push File.expand_path("../lib", __FILE__)
require "roar/version"

Gem::Specification.new do |s|
  s.name        = "roar"
  s.version     = Roar::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nick Sutterer"]
  s.email       = ["apotonick@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/roar"
  s.summary     = %q{Resource-oriented architectures in Ruby.}
  s.description = %q{Streamlines the development of RESTful, resource-oriented architectures in Ruby.}
  s.license = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "representable", ">= 2.0.1", "<= 3.0.0"

  s.add_development_dependency "rake", ">= 0.10.1"
  s.add_development_dependency "test_xml", "0.1.6"
  s.add_development_dependency "minitest",	">= 5.4.2"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "sinatra-contrib"
  s.add_development_dependency "virtus", ">= 1.0.0"
  s.add_development_dependency "faraday"
  s.add_development_dependency "json"
end
