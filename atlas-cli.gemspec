
$: << File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name = 'atlas-cli'
  s.version = '1.0.0'

  s.required_rubygems_version = ">= 1.2"
  s.authors = ["Carl Myers"]
  s.date = Time.new.strftime("%Y-%m-%d")
  s.description = 'Command Line Tool for interacting with Atlassian Applications'
  s.email = ['cmyers@palantir.com']
  s.files = ['README.md'] + Dir['lib/**/*'] + Dir['bin/**/*'] + ['Gemfile'] + ['atlas-cli.gemspec']
  s.homepage = 'https://www.github.com/palantir'
  s.require_paths = ["lib"]
  s.bindir = ["bin"]
  s.executables = Dir.glob(File.join('bin', '*')).map {|d| File.basename(d) }
  s.summary = s.description

  # library dependencies (needed by lib/* )
  s.add_dependency('andand')
  s.add_dependency('awesome_print')
  s.add_dependency('highline') # for pw console entry
  s.add_dependency('httpclient')
  s.add_dependency('json')
  s.add_dependency('log4r')
  # TODO: when we are again able to depend upon the real gem, add this back in:
  # s.add_dependency('terminal-table')
end
