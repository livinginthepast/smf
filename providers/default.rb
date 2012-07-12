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

  log("***** INSTALL: #{name}"){level :debug}
  user = new_resource.credentials_user
  xml_path = "#{new_resource.service_path}/#{new_resource.manifest_type}"
  xml_file = "#{xml_path}/#{name}.xml"
  tmp_file = "/tmp/#{name}.xml.tmp.#{$$}"

  directory "#{xml_path}" do
  end

  smf_service = service name do
    action :nothing
  end

  Chef::Resource::Rbac.definitions << name

  if user != "root"
    Chef::Resource::Rbac.permissions[user] ||= []
    Chef::Resource::Rbac.permissions[user] << name
  end

  xml_writer = SMF::XMLWriter.new(new_resource)
  # write file at all times
  ruby_block "create SMF manifest file #{xml_file} into #{tmp_file}" do
    block do
      ::File.open(tmp_file, "w") do |file|
        file.puts xml_writer.to_xml
      end
    end
  end

  execute "move the new #{xml_file} in place if changed" do
    command "cp #{tmp_file} #{xml_file}"
    not_if { `diff #{xml_file} #{tmp_file}`.chomp.empty? }
  end

  execute "remove generated temp file #{tmp_file}" do
    command "rm -f #{tmp_file}"
    only_if "ls #{tmp_file}"
  end

  auth = rbac name
  auth.run_action(:define)
  execute "import manifest" do
    command "svccfg import #{xml_file}"
    notifies :apply, auth unless user == "root"
  end
end

action :redefine do
  name = new_resource.name
  execute "add SMF authorization to allow RBAC" do
    command "svccfg -s #{name} setprop general/action_authorization=astring: 'solaris.smf.manage.#{name}'"
  end
  execute "add SMF value to allow RBAC" do
    command "svccfg -s #{name} setprop general/value_authorization=astring: 'solaris.smf.value.#{name}'"
  end
  execute "reload service" do
    command "svcadm refresh #{name}"
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
