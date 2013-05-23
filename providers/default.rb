#
# Cookbook Name:: smf
# Provider:: smf
#
# Copyright 2011, ModCloth, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

action :install do
  name = new_resource.name

  Chef::Log.debug("***** INSTALL: #{name}")
  user = new_resource.user || new_resource.credentials_user || 'root'
  xml_path = "#{new_resource.service_path}/#{new_resource.manifest_type}"
  xml_file = "#{xml_path}/#{name}.xml"
  tmp_file = "/tmp/#{name}.xml.tmp.#{$$}"

  ruby_block 'extract service long name from SMF if it already exists' do
    block do
      new_resource.fmri `svcs -H -o FMRI #{new_resource.name} | awk 'BEGIN { FS=":"}; {print $2}'`.strip
    end
  end

  directory xml_path do
  end

  service name do
    action :nothing
  end

  xml_writer = SMF::XMLWriter.new(new_resource)
  # write file at all times
  ruby_block "create SMF manifest file #{xml_file} into #{tmp_file}" do
    block do
      ::File.open(tmp_file, 'w') do |file|
        file.puts xml_writer.to_xml
      end
    end
  end

  xml_changed = false

  ruby_block "check if #{xml_file} has changed" do
    block do
      xml_changed = !(::File.exists?(xml_file) && `diff #{xml_file} #{tmp_file}`.chomp.empty?)
    end
  end

  execute "move the new #{xml_file} in place if changed" do
    command "cp #{tmp_file} #{xml_file}"
    only_if { xml_changed }
  end

  rbac name do
    action :create
  end

  execute "import manifest from #{xml_file}" do
    command "svccfg import #{xml_file}"
    only_if { xml_changed }
  end

  execute "remove generated temp file #{tmp_file}" do
    command "rm -f #{tmp_file}"
    only_if { ::File.exists?(tmp_file) }
  end

  rbac_auth "Add RBAC for #{name} to #{user}" do
    user user
    auth name
    not_if { user == "root" }
  end

  # If we are overwriting properties from an old SMF definition (from pkgsrc, etc)
  # there may be redundant XML files that we want to dereference
  execute "remove #{name} service references to old manifest files" do
    command "svccfg -s #{name} delprop `svcprop #{name} | grep manifestfiles | grep -v #{xml_file} | awk '{ print $1 }'` && svcadm refresh #{name}"
    only_if { `svcprop #{name} | grep -c manifestfiles`.strip.to_i > 1 }
  end
end

action :add_rbac do
  name = new_resource.name

  rbac name do
    action :create
  end

  execute "add SMF authorization to allow RBAC for #{name}" do
    command "svccfg -s #{name} setprop general/action_authorization=astring: 'solaris.smf.manage.#{name}'"
    not_if "svcprop -p general/action_authorization #{name}"
    notifies :reload, "service[#{name}]"
  end
  execute "add SMF value to allow RBAC for #{name}" do
    command "svccfg -s #{name} setprop general/value_authorization=astring: 'solaris.smf.value.#{name}'"
    not_if "svcprop -p general/value_authorization #{name}"
    notifies :reload, "service[#{name}]"
  end
end

action :delete do
  service new_resource.name do
    action [:stop, :disable]
  end

  execute "remove service #{new_resource.name} from SMF" do
    command "svccfg delete #{new_resource.name}"
    only_if "svcs -a #{new_resource.name}"
  end
end
