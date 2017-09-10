# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "affinity_propagation/version"

Gem::Specification.new do |spec|
  spec.name          = "affinity_propagation"
  spec.version       = AffinityPropagation::VERSION
  spec.authors       = ["Shahbaz Javeed"]
  spec.email         = ["sjaveed@gmail.com"]

  spec.summary       = %q{An implementation of the affinity propagation clustering algorithm by Frey and Dueck}
  spec.description   = %q{
    Affinity Propagation is a clustering algorithm that does not require pre-specifying the number of clusters like
    k-means and other similar algorithms do.  This is a ruby implementation of the original version defined by Frey and
    Dueck in http://www.psi.toronto.edu/affinitypropagation/FreyDueckScience07.pdf
  }
  spec.homepage      = "https://github.com/sjaveed/affinity_propagation"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "activesupport"
end
