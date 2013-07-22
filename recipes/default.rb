
## These libraries need to be installed when the cookbook
#  is loaded, otherwise they are not available when the
#  cookbook runs.

package 'libxslt' do
  action :nothing
end.run_action(:install)

ruby_block "setup nokogiri environment" do
  block do
    ENV['NOKOGIRI_USE_SYSTEM_LIBRARIES'] = 'true'
  end

  action :nothing
end.run_action(:run)

chef_gem 'nokogiri'
require 'nokogiri'
