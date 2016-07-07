source "https://rubygems.org"

group :test do
    gem "listen", "<=3.0.6"
    gem "nokogiri", "<=1.6.7.2"
    gem "rake"
    gem "rspec"
    gem "puppet", ENV['PUPPET_GEM_VERSION'] || '~> 3.8.3'
    gem "rspec-puppet"
    gem "puppetlabs_spec_helper"
    gem 'rspec-puppet-utils'
    gem 'hiera-puppet-helper', :git => 'https://github.com/bobtfish/hiera-puppet-helper.git'
    gem "metadata-json-lint"
    gem 'puppet-syntax'
    gem 'puppet-lint'
    gem 'rspec-puppet-facts'
    gem "rest-client", "<=1.8.0"
end

group :integration do
    gem "beaker"
    gem "beaker-rspec"
    gem "vagrant-wrapper"
    gem 'serverspec'
end

group :development do
    gem "travis"
    gem "travis-lint"
    gem "puppet-blacksmith"
    gem "guard-rake"
end
