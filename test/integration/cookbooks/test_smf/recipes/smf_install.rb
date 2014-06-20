include_recipe 'smf'

smf 'thing' do
  start_command 'true'
  stop_command 'true'
  duration 'transient'
  notifies :restart, 'service[thing]'
end

service 'thing'
