# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jimmy/version'

Gem::Specification.new do |spec|
  spec.name          = 'jimmy'
  spec.version       = Jimmy::VERSION
  spec.authors       = ['Simply Business']
  spec.email         = ['tech@simplybusiness.co.uk']

  spec.summary       = ''
  spec.description   = ''
  spec.homepage      = 'https://github.com/simplybusiness/jimmy'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_dependency 'rack', ['>= 1.4', '< 2.0']
  spec.add_dependency 'actionpack'
end
