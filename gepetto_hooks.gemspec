$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'gepetto_hooks/version'

Gem::Specification.new do |s|
  s.name = 'gepetto_hooks'
  s.version = GepettoHooks::VERSION
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = 'Geppetto Bot for an event driven web'
  s.homepage = 'https://github.com/puppetlabs/puppet-webhooks'
  s.email = 'jeff@puppetlabs.com'
  s.authors = [ 'Jeff McCune' ]
  s.has_rdoc = false

  s.description = s.summary

  s.files = %w{ LICENSE README.md Rakefile config.ru }
  s.files += Dir.glob("lib/**/*")
  s.files += Dir.glob("spec/**/*")
  s.files += Dir.glob("public/**/*")
end
