
require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

def load_current_resource
  @current_resource = Chef::Resource::Smf.new(new_resource.name)
  @current_resource.load

  find_fmri
end

action :install do
  create_directories
  write_manifest
  create_rbac_definitions
  import_manifest
  deduplicate_manifest
  add_rbac_permissions

  new_resource.updated_by_last_action(smf_changed?)
  new_resource.save_checksum
end

action :add_rbac do
  create_rbac_definitions

  service new_resource.name

  manage = execute "add SMF authorization to allow RBAC for #{new_resource.name}" do
    command "svccfg -s #{new_resource.name} setprop general/action_authorization=astring: 'solaris.smf.manage.#{new_resource.name}'"
    not_if "svcprop -p general/action_authorization #{new_resource.name}"
    notifies :reload, "service[#{new_resource.name}]"
  end

  value = execute "add SMF value to allow RBAC for #{new_resource.name}" do
    command "svccfg -s #{new_resource.name} setprop general/value_authorization=astring: 'solaris.smf.value.#{new_resource.name}'"
    not_if "svcprop -p general/value_authorization #{new_resource.name}"
    notifies :reload, "service[#{new_resource.name}]"
  end

  new_resource.updated_by_last_action(manage.updated_by_last_action? || value.updated_by_last_action?)
end

action :delete do
  new_resource.updated_by_last_action(false)

  if smf_exists?
    service new_resource.name do
      action [:stop, :disable]
    end

    execute "remove service #{new_resource.name} from SMF" do
      command "svccfg delete #{new_resource.name}"
    end

    delete_manifest
    new_resource.remove_checksum

    new_resource.updated_by_last_action(true)
  end
end

private

def smf_exists?
  shell_out("svcs -a #{new_resource.name}").exitstatus == 0
end

def smf_changed?
  @current_resource.checksum != new_resource.checksum
end

def find_fmri
  fmri_check = shell_out(%{svcs -H -o FMRI #{new_resource.name} | awk 'BEGIN { FS=":"}; {print $2}'})
  if fmri_check.exitstatus == 0
    new_resource.fmri fmri_check.stdout.chomp
  else
    new_resource.fmri "/#{new_resource.manifest_type}/management/#{new_resource.name}"
  end
end

def create_directories
  directory new_resource.xml_path
end

def write_manifest
  return unless smf_changed?

  Chef::Log.debug "Writing SMF manifest for #{new_resource.name}"
  ::File.open(new_resource.xml_file, 'w') do |file|
    file.puts SMFManifest::XMLBuilder.new(new_resource).to_xml
  end
end

def delete_manifest
  return unless ::File.exists?(new_resource.xml_file)

  Chef::Log.debug "Removing SMF manifest for #{new_resource.name}"
  ::File.delete(new_resource.xml_file)
end

def create_rbac_definitions
  rbac new_resource.name do
    action :create
  end
end

def add_rbac_permissions
  user = new_resource.user || new_resource.credentials_user || 'root'

  rbac_auth "Add RBAC for #{new_resource.name} to #{user}" do
    user user
    auth new_resource.name
    not_if { user == "root" }
  end
end

def import_manifest
  return unless smf_changed?

  Chef::Log.debug("importing SMF manifest #{new_resource.xml_file}")
  shell_out!("svccfg import #{new_resource.xml_file}")
end

def deduplicate_manifest
  # If we are overwriting properties from an old SMF definition (from pkgsrc, etc)
  # there may be redundant XML files that we want to dereference
  name = new_resource.name

  duplicate_manifest = shell_out("svcprop #{name} | grep -c manifestfiles").stdout.strip.to_i > 1
  if duplicate_manifest
    Chef::Log.debug "Removing duplicate SMF manifest reference from #{name}"
    shell_out! "svccfg -s #{name} delprop `svcprop #{name} | grep manifestfiles | grep -v #{new_resource.xml_file} | awk '{ print $1 }'` && svcadm refresh #{name}"
  end
end
