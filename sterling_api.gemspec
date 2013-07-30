# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sterling_api/version"

Gem::Specification.new do |s|
  s.name        = "sterling_api"
  s.version     = SterlingApi::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Manny Rodriguez"]
  s.email       = ["manny@7compass.com"]
  s.homepage    = "https://github.com/7compass/sterling_api"
  s.summary     = %q{Sterling Api}
  s.description = %q{For requesting background checks}

  s.rubyforge_project = "sterling_api"

  s.add_runtime_dependency("nokogiri", "> 0")
  s.add_runtime_dependency("net/http", "> 0")
  s.add_runtime_dependency("net/https", "> 0")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.license = 'MIT'
end
