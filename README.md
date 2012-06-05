# SMF

## Description

Service Management Facility (SMF) is a tool in Solaris (and Solaris-like
operating systems) for that treats services as first class objects of
the system. It provides an XML syntax for declaring how the system can
interact with an control a service.

The SMF cookbook provides providers for registering a service with SMF.

## Requirements

Any operating system that uses SMF, ie Solaris or SmartOS.

## Resources and Providers



## Attributes

* `credentials_user` - User to run service commands as
* `start_command`
* `start_timeout`
* `stop_command` - defaults to `:kill`, which basically means it will destroy every PID generated from the start command
* `stop_timeout`
* `restart_command` - defaults to `stop_command`, then `start_command`
* `restart_timeout`
* `working_directory` - PWD that SMF should cd to in order to run commands
* `duration` - Can be either `contract`, `wait` or `transient`, but defaults to `contract`. See the Duration section below.
* `locale` - Character encoding to use (default "C")
* `environment` - Hash - Environment variables to set while running commands
* `service_path` - defaults to `/var/svc/manifest`
* `manifest_type` - defaults to `application`
* `property_groups` - Hash - This should be in the form `{"group name" => {"type" => "application", "key" => "value", ...}}`


## Usage

    smf "my-service" do
      credentials_user "non-root-user"
      
      start_command "my-service start"
      start_timeout 10
      
      stop_command "pkill my-service"
      stop_command  5
      
      restart_command "my-service restart"
      restart_timeout 60
      
      environment "PATH" => "/home/non-root-user/bin",
                  "RAILS_ENV" => "staging"
      
      locale "C"
      
      manifest_type "application"
      service_path  "/var/svc/manifest"
    end
    
    service "my-service" do
      action :enable
    end
    
    service "my-service" do
      action :restart
    end

## Duration

There are several different ways that SMF can track your service. By default it uses `contract`. 
Basically, this means that it will keep track of the PIDs of all daemonized processes generated from `start_command`.
If SMF sees that processes are cycling, it may try to restart the service. If things get too hectic, it
may think that your service is flailing and put it into maintenance mode. If this is normal for your service,
for instance if you have a master that occasionally reaps processes, you may want to specify additional
configuration options.

If you have a job that you want managed by SMF, but which is not daemonized, another duration option is
`transient`. In this mode, SMF will not watch any processes, but will expect that the main process exits cleanly.
This can be used, for instance, for a script that must be run at boot time, or for a script that you want to delegate
to particular users with Role Based Access Control. In this case, the script can be registered with SMF to run as root,
but with the start_command delegated to your user.

A third option is `wait`. 

## Property Groups

Property Groups are where you can store extra information for SMF to use later. They should be used in the
following format:

    smf "my-service" do
      start_command "do-something"
      property_groups({
        "config" => {
          "type" => "application",
          "my-property" => "property value"
        }
      })
    end

`type` will default to `application`, and is used in the manifest XML to declare how the property group will be
used. For this reason, `type` can not be used as a property name (ie variable).

One way to use property groups is to pass variables on to commands, as follows:

    rails_env = node["from-chef-environment"]["rails-env"]
    
    smf "unicorn" do
      start_command "bundle exec unicorn_rails -c /home/app_user/app/current/config/%{config/rails_env} -E %{config/rails_env} -D"
      start_timeout 300
      restart_command ":kill -SIGUSR2"
      restart_timeout 300
      working_directory "/home/app_user/app/current"
      property_groups({
        "config" => {
          "rails_env" => rails_env
        }
      })
    end

This is especially handy if you have a case where your commands may come from role attributes, but can
only work if they have access to variables set in an environment or computed in a recipe.