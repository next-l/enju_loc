$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "enju_loc/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "enju_loc"
  s.version     = EnjuLoc::VERSION
  s.authors     = ["Masao Takaku"]
  s.email       = ["tmasao@acm.org"]
  s.homepage    = "https://github.com/masao/enju_loc"
  s.summary     = "LoC SRU wrapper for Next-L Enju"
  s.description = "This module allow users to search and import bibliographic records from Library of Congress via SRU-based API."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
end
