lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'boxr/version'

Gem::Specification.new do |spec|
  spec.name          = 'boxr'
  spec.version       = Boxr::VERSION
  spec.authors       = ['Chad Burnette', 'Xavier Hocquet']
  spec.email         = ['chadburnette@me.com', 'xhocquet@gmail.com']
  spec.summary       = 'A Ruby client library for the Box V2 Content API.'
  spec.description   = 'Wraps the Box V2 Content API: files, folders, metadata, users and more.'
  spec.homepage      = 'https://github.com/cburnette/boxr'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.3'

  spec.metadata = {
    'source_code_uri' => 'https://github.com/cburnette/boxr',
    'bug_tracker_uri' => 'https://github.com/cburnette/boxr/issues',
    'changelog_uri' => 'https://github.com/cburnette/boxr/releases'
  }

  spec.add_development_dependency 'awesome_print', '~> 1.8'
  spec.add_development_dependency 'dotenv', '~> 2.8'
  spec.add_development_dependency 'parallel', '>= 1.27', '< 3'
  spec.add_development_dependency 'rake', '~> 13.1'
  spec.add_development_dependency 'rspec', '~> 3.13.1'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.7.1'
  spec.add_development_dependency 'rubocop-rspec', '>= 3.10.2', '< 4'
  spec.add_development_dependency 'rubyzip', '~> 3.4'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'sin_lru_redux', '~> 2.5'
  spec.add_development_dependency 'webmock', '~> 3.19'

  spec.add_runtime_dependency 'addressable', '>= 2.9.1', '< 3'
  spec.add_runtime_dependency 'base64', '>= 0.1', '< 1'
  spec.add_runtime_dependency 'hashie', '>= 5.1', '< 6'
  spec.add_runtime_dependency 'httpclient', '>= 2.10', '< 3'
  spec.add_runtime_dependency 'jwt', '>= 2.8', '< 4'
end
