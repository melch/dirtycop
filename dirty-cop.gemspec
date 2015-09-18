# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dirty/cop/version'

Gem::Specification.new do |spec|
  spec.name          = "dirty-cop"
  spec.version       = Dirty::Cop::VERSION
  spec.authors       = ["Adam Hess"]
  spec.email         = ["adamhess1991@gmail.com"]
  spec.summary       = %q{Corrupt cop that avoids unchanged violations}
  spec.description   = %q{Takes your current diff as the input for rubocop}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = ['dirty']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

    spec.add_dependency 'rubocop'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
