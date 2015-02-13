# encoding: utf-8
# Cookbook Name:: smf
# spec:: rspec_helper
#

require 'chef'

Dir['spec/support/**/*.rb'].each do |file|
  require File.join('.', file)
end
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
