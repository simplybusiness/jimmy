# coding: utf-8

lib = File.expand_path('lib', __dir__)
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

  spec.summary       = 'Middleware to format logs as JSON.'
  spec.description   = 'Jimmy is middleware that formats logs as JSON so they can be easily ingested with Log Stash and fed into Kibana.'
  spec.homepage      = 'https://github.com/simplybusiness/jimmy'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.5.0'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  spec.add_dependency 'actionpack'
  spec.add_dependency 'dry-struct'
  spec.add_dependency 'rack', '>= 1.4'
end
