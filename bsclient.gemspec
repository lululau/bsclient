require_relative 'lib/bsclient/version'

Gem::Specification.new do |spec|
  spec.name          = "bsclient"
  spec.version       = BSClient::VERSION
  spec.authors       = ["Liu Xiang"]
  spec.email         = ["liuxiang@ktjr.com"]

  spec.summary       = %q{Register bs account}
  spec.description   = %q{Register bs account}
  spec.homepage      = "https://github.com/lululau/bsga"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'faraday'
  spec.add_dependency 'thor', '~> 0.20.0'
  spec.add_dependency 'pry', '~> 0.13.1'
  spec.add_dependency 'pry-byebug', '~> 3.9.0'
  spec.add_dependency 'pry-doc', '>= 1.0.0'
end
