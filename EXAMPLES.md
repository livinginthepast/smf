SMF Examples
============

Below are some of the working examples using the SMF cookbook.

### Shared Helpers

These live in a library provider somewhere, and help start/stop pid-based processes. This strategy may
be required when using the `wait` duration.

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

### Unicorn

Here is an example that uses duration `wait`. Because of this, SMF does
not watch pids in a contract, and the `stop_command` needs to figure out
what processes are running.

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
  user user
  start_command start_helper("(bundle exec unicorn_rails -c #{unicorn_conf} -E #{rails_env} -D)")
  start_timeout 90
  stop_command stop_helper(unicorn_pid, :term)
  stop_timeout 30
  duration "wait"
  working_directory "#{current_path}"
end
```

This example, while more verbose, uses the default duration of
`contract`, and so SMF can take care of pid management. We are able to
use `:kill` in the stop and restart commands.

```ruby
current_path = "/home/#{user}/#{node.app.dir}"
rails_env = node.app.rails_env
unicorn_path = "/home/#{user}/.rbenv/shims:/home/#{user}/.rbenv/bin"
garbage_collection_settings = {
  "RUBY_GC_MALLOC_LIMIT": 50000000,
  "RUBY_HEAP_MIN_SLOTS": 500000,
  "RUBY_HEAP_SLOTS_GROWTH_FACTOR": 1,
  "RUBY_HEAP_SLOTS_INCREMENT": 250000
}

smf "unicorn" do
  user user

  start_command "bundle_exec unicorn_rails -c %{config/current_path}/config/unicorn/%{config/rails_env}.rb -E %{config/rails_env} -D"
  start_timeout 90
  stop_command ":kill"           ## this is redundant, as it is the default
  stop_timeout 30
  restart_command ":kill -SIGUSR2"
  restart_timout 120

  environment(
    {"PATH" => unicorn_path}.merge(garbage_collection_settings)
  )

  ## If you get into a case where the unicorn master is frequently reaping workers, SMF may notice 
  ## and put the service into maintenance mode. Instead, we tell SMF to ignore core dumps and 
  ## signals to children.
  ignore ["core","signal"]
  property_groups({
    "config" => {
      "rails_env" => rails_env,
      "current_path" => current_path
    }
  })
  working_directory current_path
end
```

### Sidekiq

```ruby
rails_env     = node[:rails_env]
user          = node[:app][:user]
dir           = "/home/#{user}/#{node[:app][:dir]}"

sidekiq_yml   = "#{dir}/config/sidekiq.yml"
sidekiq_pid   = "#{dir}/tmp/pids/sidekiq.pid"
sidekiq_log   = "#{dir}/log/sidekiq.log"

smf "sidekiq" do
  user user
  start_command "bundle exec sidekiq -e #{rails_env} -C #{sidekiq_yml} -P #{sidekiq_pid} >> #{sidekiq_log} 2>&1 &"
  start_timeout 30
  stop_command ':kill'
  stop_timeout 15
  working_directory "#{dir}"

  environment 'BUNDLE_GEMFILE' => "#{dir}/Gemfile"
              'PATH' => '/opt/rbenv/versions/1.9.3-p392:/opt/local/bin'
end

sidekiq_monitor_run_path    = "#{dir}/sidekiq_monitor.ru"
sidekiq_monitor_config_path = "#{dir}/config/unicorn/sidekiq_monitor.rb"

smf "sidekiq-monitor" do
  user user
  start_command "bundle exec unicorn -c #{sidekiq_monitor_config_path} -E #{rails_env} -D #{sidekiq_monitor_run_path} 2>&1)"
  start_timeout 30
  stop_command ':kill'
  stop_timeout 15
  working_directory "#{dir}"

  environment 'BUNDLE_GEMFILE' => "#{dir}/Gemfile"
              'PATH' => '/opt/rbenv/versions/1.9.3-p392:/opt/local/bin'
end
```


## TODO

* tests... this was built before I knew about chefspec
