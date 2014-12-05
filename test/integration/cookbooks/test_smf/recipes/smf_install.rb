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
      property2: 'deleteme',
      property3: '("complex value" "simple" "basic")',
      property4: 'deletethisvalue',
      property5: 'deletethisvalueglob'
    }
  })
end
