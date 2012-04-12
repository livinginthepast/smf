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

  user = new_resource.credentials_user
  xml_path = "#{new_resource.service_path}/#{new_resource.manifest_type}"
  xml_file = "#{xml_path}/#{name}.xml"

  directory "#{xml_path}" do
  end

  smf_service = service name do
    action :nothing
  end

  authorization = smf_authorization name

  permissions = ["solaris.smf.manage.#{name}", "solaris.smf.value.#{name}"]
  Chef::Resource::SmfAuthorization.definitions << name
  authorization.run_action(:define)

  if user != "root"
    Chef::Resource::SmfAuthorization.permissions[user] ||= []
    Chef::Resource::SmfAuthorization.permissions[user] += permissions
  end

  xml_writer = SMF::XMLWriter.new(new_resource)
  bash "create SMF manifest file #{xml_file}" do
    user "root"
    cwd xml_path
    code <<-END
      cat > #{xml_file} <<FILE
#{xml_writer.to_xml}
FILE
    END

    not_if "ls #{xml_file}"
  end

  execute "import manifest" do
    command "svccfg import #{xml_file}"
    notifies :apply, authorization unless user == "root"
  end
end

