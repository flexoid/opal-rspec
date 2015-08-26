source 'https://rubygems.org'
gemspec

unless Dir['rspec{,-{core,expectations,mocks,support}}'].any?
  warn 'Run: "git submodule update --init" to get RSpec sources'
end

# Opal 0.9 still in development
# gem 'opal', git: 'https://github.com/opal/opal.git'
gem 'capybara-webkit'
gem 'selenium-webdriver'

# These need to come from our local path in order for create_requires.rb to work properly
gem 'rspec',              path: 'rspec'
gem 'rspec-support',      path: 'rspec-support'
gem 'rspec-core',         path: 'rspec-core'
gem 'rspec-mocks',        path: 'rspec-mocks'
gem 'rspec-expectations', path: 'rspec-expectations'

