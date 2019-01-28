# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'boxr/version'

Gem::Specification.new do |spec|
  spec.name          = 'boxr'
  spec.version       = Boxr::VERSION
  spec.authors       = ['Chad Burnette']
  spec.email         = ['chadburnette@me.com']
  spec.summary       = 'A Ruby client library for the Box V2 Content API.'
  spec.description   = ""
  spec.homepage      = 'https://github.com/cburnette/boxr'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'bundler-audit'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'lru_redux'

  spec.add_runtime_dependency 'httpclient'
  spec.add_runtime_dependency 'hashie'
  spec.add_runtime_dependency 'addressable'
  spec.add_runtime_dependency 'jwt'
end
