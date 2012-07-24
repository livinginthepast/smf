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
* `ignore` - Array - Faults to ignore in subprocesses. For example, if core dumps in children are handled by a master process and you don't want SMF thinking the service is exploding, you can ignore ["core", "signal"].

## Usage

```ruby
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
```

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

## Ignore

Sometimes you have a case where your service behaves poorly. The Ruby server Unicorn, for example, has a master 
process that likes to kill its children. This causes core dumps that SMF will interpret to be a failing service.
Instead you can `ignore ["core", "signal"]` and SMF will stop caring about core dumps.

## Property Groups

Property Groups are where you can store extra information for SMF to use later. They should be used in the
following format:

```ruby
smf "my-service" do
  start_command "do-something"
  property_groups({
    "config" => {
      "type" => "application",
      "my-property" => "property value"
    }
  })
end
```

`type` will default to `application`, and is used in the manifest XML to declare how the property group will be
used. For this reason, `type` can not be used as a property name (ie variable).

One way to use property groups is to pass variables on to commands, as follows:

```ruby
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
```

This is especially handy if you have a case where your commands may come from role attributes, but can
only work if they have access to variables set in an environment or computed in a recipe.

# Working Examples

Below are some of the working examples using the SMF cookbook.

## Shared Helpers

These live in a library provider somewhere, and help start/stop pid-based processes.

```ruby
module ProcessHelpers
  def start_helper(cmd)
    "#{node[:bash]} -c 'export HOME=/home/#{node[:app][:user]} && export JAVA_HOME=/opt/local/java/sun6/ && export PATH=$JAVA_HOME/bin:/opt/local/bin:/opt/local/sbin:/usr/bin:/usr/sbin:$PATH && source $HOME/.bashrc && cd $HOME/#{node[:app][:dir]} && #{cmd}'"
  end
  def stop_helper(pid, sig = :term)
    "#{node[:bash]} -c 'if [ -f #{pid} ]; then kill -#{sig.to_s.upcase} `cat #{pid}` 2>/dev/null; fi; exit 0'"
  end
end
```

## Unicorn

```ruby
class Chef::Resource::Smf
  include ::ProcessHelpers
end

rails_env     = node[:rails_env]
user          = node[:app][:user]

current_path  = "/home/#{user}/#{node[:app][:dir]}"
unicorn_conf  = "#{current_path}/config/unicorn/#{rails_env}.rb"
unicorn_pid   = "#{current_path}/tmp/pids/unicorn.pid"

smf "unicorn" do
  credentials_user user
  start_command start_helper("(bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D)")
  start_timeout 90
  stop_command stop_helper(unicorn_pid, :term)
  stop_timeout 30
  duration "wait"
  working_directory "#{current_path}"
end
```

## SideKiq

```ruby
class Chef::Resource::Smf
  include ::ProcessHelpers
end

rails_env     = node[:rails_env]
user          = node[:app][:user]
dir           = "/home/#{user}/#{node[:app][:dir]}"

sidekiq_yml   = "#{dir}/config/sidekiq.yml"
sidekiq_pid   = "#{dir}/tmp/pids/sidekiq.pid"
sidekiq_log   = "#{dir}/log/sidekiq.log"

smf "sidekiq" do
  credentials_user user
  start_command start_helper("(bundle exec sidekiq -e #{rails_env} -C #{sidekiq_yml} -P #{sidekiq_pid} >> #{sidekiq_log} 2>&1 &)")
  start_timeout 30
  stop_command stop_helper(sidekiq_pid, :term)
  stop_timeout 15
  working_directory "#{dir}"
end

sidekiq_monitor_pid         = "#{dir}/tmp/pids/sidekiq_monitor.pid"
sidekiq_monitor_run_path    = "#{dir}/sidekiq_monitor.ru"
sidekiq_monitor_config_path = "#{dir}/config/unicorn/sidekiq_monitor.rb"

smf "sidekiq-monitor" do
  credentials_user user
  start_command start_helper("(BUNDLE_GEMFILE=#{dir}/Gemfile bundle exec unicorn -c #{sidekiq_monitor_config_path} -E #{rails_env} -D #{sidekiq_monitor_run_path} 2>&1)")
  start_timeout 30
  stop_command stop_helper(sidekiq_monitor_pid, :term)
  stop_timeout 15
  working_directory "#{dir}"
end
```
