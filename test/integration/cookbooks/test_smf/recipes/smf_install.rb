include_recipe 'smf'

smf 'thing' do
  fmri 'thing'
  start_command 'true'
  stop_command 'true'
  duration 'transient'
  notifies :restart, 'service[thing]'
end

service 'thing'

smf 'create_thing2' do
  name 'thing2'
  fmri 'thing2'
  start_command 'true'
  stop_command 'true'
  duration 'transient'
  property_groups ({
    testgroup: {
      property1: 'true',
      property3: '("complex value" "simple" "basic")'
    }
  })
end

smf 'modify_thing2' do
  action :setprop
  name 'thing2'
  fmri 'thing2'
  property_groups ({
    testgroup: {
      property1: 'true',
      property3: '("complex modified value" "simple" "basic")'
    }
  })
end

smf 'modify_name-service-cache' do
  action :setprop
  name 'name-service-cache'
  property_groups ({
    config: {
      'per_user_nscd_time_to_live' => 240
    }
  })
end
