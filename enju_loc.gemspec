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
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "enju_seed", "~> 0.1.1.pre11"
  s.add_dependency "nokogiri"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails", "~> 3.0.2"
  s.add_development_dependency "vcr"
  s.add_development_dependency "fakeweb"
  s.add_development_dependency "enju_leaf", "~> 1.1.0.rc14"
  s.add_development_dependency "sunspot_solr", "~> 2.1"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "enju_subject", "~> 0.1.0.pre27"
end
