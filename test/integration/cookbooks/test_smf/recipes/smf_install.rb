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
    property1: true,
    property3: '("complex value" "simple" "basic")'
  })
end

smf 'modify_thing2' do
  name 'thing2'
  fmri 'thing2'
  action [:setprop]
  property_groups ({
    property1: true,
    property3: '("complex modified value" "simple" "basic")'
  })
end
