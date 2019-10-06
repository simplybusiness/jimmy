# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jimmy/version'

gem_version = if ENV['GEM_PRE_RELEASE'].nil? || ENV['GEM_PRE_RELEASE'].empty?
                Jimmy::VERSION
              else
                "#{Jimmy::VERSION}.#{ENV['GEM_PRE_RELEASE']}"
              end

Gem::Specification.new do |spec|
  spec.name          = 'jimmy'
  spec.version       = gem_version
  spec.authors       = ['Simply Business']
  spec.email         = ['tech@simplybusiness.co.uk']

  spec.summary       = ''
  spec.description   = ''
  spec.homepage      = 'https://github.com/simplybusiness/jimmy'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'rack', '>= 1.4'
  spec.add_dependency 'actionpack'
  spec.add_dependency 'dry-struct'
end
