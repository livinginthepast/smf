#

require 'serverspec'
set :backend, :exec
set :path, '/opt/chef/embedded/bin:/sbin:/usr/sbin:$PATH'
