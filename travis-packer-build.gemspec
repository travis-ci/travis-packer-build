# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'travis/packer_build/version'

Gem::Specification.new do |spec|
  spec.name = 'travis-packer-build'
  spec.version = Travis::PackerBuild::VERSION
  spec.authors = ['Dan Buch', 'Carmen Andoh']
  spec.email = ['dan@travis-ci.org', 'carmen@travis-ci.org']

  spec.summary = 'Look at a packer template & decide if it should be built!'
  spec.description = spec.summary + '  For reeeeal.'
  spec.homepage = 'https://github.com/travis-ci/travis-packer-build'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.required_ruby_version = '>= 2.4'

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w[lib]

  spec.add_runtime_dependency 'faraday', '~> 0.9'
  spec.add_runtime_dependency 'gh', '~> 0.14'
  spec.add_runtime_dependency 'git', '~> 1'

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'foodcritic', '~> 6'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'pry-coolline', '~> 0.2'
  spec.add_development_dependency 'rake', '~> 10'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'rubocop', '~> 0.55'
  spec.add_development_dependency 'simplecov', '~> 0.12'
end
