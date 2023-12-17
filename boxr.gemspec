# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'boxr/version'

Gem::Specification.new do |spec|
  spec.name          = "boxr"
  spec.version       = Boxr::VERSION
  spec.authors       = ["Chad Burnette", "Xavier Hocquet"]
  spec.email         = ["chadburnette@me.com", "xhocquet@gmail.com"]
  spec.summary       = "A Ruby client library for the Box V2 Content API."
  spec.description   = ""
  spec.homepage      = "https://github.com/cburnette/boxr"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0'

  spec.add_development_dependency "bundler", "~> 2.3"
  spec.add_development_dependency "rake", "~> 13.1"
  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "simplecov", "~> 0.9"
  spec.add_development_dependency "dotenv", "~> 2.8"
  spec.add_development_dependency "awesome_print", "~> 1.8"
  spec.add_development_dependency "lru_redux", "~> 1.1"
  spec.add_development_dependency "parallel", "~> 1.0"
  spec.add_development_dependency "rubyzip", "~> 2.3"

  spec.add_runtime_dependency "httpclient", "~> 2.8"
  spec.add_runtime_dependency "hashie", ">= 3.5", "< 6"
  spec.add_runtime_dependency "addressable", "~> 2.8"
  spec.add_runtime_dependency "jwt", ">= 1.4", "< 3"
end
