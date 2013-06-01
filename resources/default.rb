#
# Cookbook Name:: smf
# Resource:: smf
#
# Copyright 2012, ModCloth, Inc.
#

actions :install, :add_rbac, :delete
default_action :install

attribute :name, :kind_of => String, :name_attribute => true, :required => true
attribute :user, :kind_of => [String, NilClass], :default => nil
attribute :group, :kind_of => [String, NilClass], :default => nil
attribute :project, :kind_of => [String, NilClass], :default => nil

attribute :start_command, :kind_of => [String, NilClass], :default => nil
attribute :start_timeout, :kind_of => Integer, :default => 5
attribute :stop_command, :kind_of => String, :default => ":kill"
attribute :stop_timeout, :kind_of => Integer, :default => 5
attribute :restart_command, :kind_of => [String, NilClass], :default => nil
attribute :restart_timeout, :kind_of => Integer, :default => 5
attribute :refresh_command, :kind_of => [String, NilClass], :default => nil
attribute :refresh_timeout, :kind_of => Integer, :default => 5

attribute :working_directory, :kind_of => [String, NilClass], :default => nil
attribute :environment, :kind_of => [Hash, NilClass], :default => nil
attribute :locale, :kind_of => String, :default => "C"

attribute :manifest_type, :kind_of => String, :default => "application"
attribute :service_path, :kind_of => String, :default => "/var/svc/manifest"

attribute :duration, :kind_of => String, :default => "contract", :regex => "(contract|wait|transient|child)"
attribute :ignore, :kind_of => [Array, NilClass], :default => nil
attribute :fmri, :kind_of => String, :default => nil

attribute :property_groups, :kind_of => Hash, :default => {}

# Deprecated
attribute :credentials_user, :kind_of => [String, NilClass], :default => nil

