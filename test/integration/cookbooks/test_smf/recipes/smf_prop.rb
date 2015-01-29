include_recipe 'smf'

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

smf 'modify-cron' do
  action :setprop
  name '/system/cron'
  property_groups ({
    startd: {
      'ignore_error' => 'signal,core'
    }
  })
end

smf 'delete_property' do
  action :delprop
  name 'thing2'
  property_groups ({
    testgroup: {
      'property2' => 240
    }
  })
end

smf 'delete_property_value' do
  action :delpropvalue
  name 'thing2'
  property_groups ({
    testgroup: {
      'property4' => 'deletethisvalue'
    }
  })
end

smf 'delete_property_value_using_glob' do
  action :delpropvalue
  name 'thing2'
  property_groups ({
    testgroup: {
      'property5' => '*glob'
    }
  })
end
