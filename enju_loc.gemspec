$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "enju_loc/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "enju_loc"
  s.version     = EnjuLoc::VERSION
  s.authors     = ["Masao Takaku"]
  s.email       = ["tmasao@acm.org"]
  s.homepage    = "https://github.com/next-l/enju_loc"
  s.summary     = "LoC SRU wrapper for Next-L Enju"
  s.description = "This module allow users to search and import bibliographic records from Library of Congress via SRU-based API."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"] - Dir["spec/dummy/log/*"] - Dir["spec/dummy/solr/{data,pids,default,development,test}/*"] - Dir["spec/dummy/tmp/*"]

  s.add_dependency "enju_subject", "~> 0.5.0.beta.1"
  s.add_dependency "faraday"

  s.add_development_dependency "enju_leaf", "~> 3.0.0.beta.1"
  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails", "~> 4.0"
  s.add_development_dependency "vcr", "~> 6.0"
  s.add_development_dependency "webmock"
  s.add_development_dependency "sunspot_solr", "~> 2.5"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "coveralls", '~> 0.8.23'
  s.add_development_dependency "appraisal"
  s.add_development_dependency "annotate"
end
