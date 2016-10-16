$:.push File.expand_path("../lib", __FILE__)

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

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"] - Dir["spec/dummy/db/*.sqlite3"] - Dir["spec/dummy/log/*"] - Dir["spec/dummy/solr/{data,pids,default,development,test}/*"] - Dir["spec/dummy/tmp/*"]

  s.add_dependency "enju_subject", "~> 0.2.0.beta.3"
  s.add_dependency "faraday"

  s.add_development_dependency "enju_leaf", "~> 1.2.0.beta.3"
  s.add_development_dependency "globalize", "~> 5.0.1"
  s.add_development_dependency "globalize-accessors"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails", "~> 3.4"
  s.add_development_dependency "vcr", "~> 3.0"
  s.add_development_dependency "webmock"
  s.add_development_dependency "sunspot_solr", "2.2.0"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "appraisal"
end
