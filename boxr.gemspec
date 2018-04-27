# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'boxr/version'

Gem::Specification.new do |spec|
  spec.name          = "boxr"
  spec.version       = Boxr::VERSION
  spec.authors       = ["Chad Burnette"]
  spec.email         = ["chadburnette@me.com"]
  spec.summary       = "A Ruby client library for the Box V2 Content API."
  spec.description   = ""
  spec.homepage      = "https://github.com/cburnette/boxr"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '~> 2.0'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "simplecov", "~> 0.9"
  spec.add_development_dependency "dotenv", "~> 0.11"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "lru_redux", "~> 0.8"

  spec.add_runtime_dependency "httpclient", "~> 2.8"
  spec.add_runtime_dependency "hashie", "~> 3.5"
  spec.add_runtime_dependency "addressable", "~> 2.3"
  spec.add_runtime_dependency "jwt", "~> 2.0"
end
