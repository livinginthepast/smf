# encoding: utf-8
# Cookbook Name:: smf
# spec:: rspec_helper
#

require_relative '../libraries/properties'
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
