require 'spec_helper'

context 'Service properties' do
  context 'creating a service' do
    describe command('svccfg export thing2') do
      its(:stdout) { is_expected.to match(/property1.*true/) }
    end
  end
  context 'modify a multivalued property value of an added service' do
    describe command('svccfg export thing2') do
      its(:stdout) { is_expected.to match(/value_node.*complex modified value/) }
      its(:stdout) { is_expected.to match(/value_node.*basic/) }
    end
  end
  context 'modify a property value of an existing service' do
    describe command('svccfg export /system/cron') do
      its(:stdout) { is_expected.to match(/ignore_error.*signal,core/) }
    end
  end
  context 'delete a property value' do
    describe command('svccfg export thing2') do
      its(:stdout) { is_expected.not_to match(/property2.*240/) }
      its(:stdout) { is_expected.not_to match(/property2.*deletethisvalue/) }
    end
  end
  context 'delete a property value using a glob pattern' do
    describe command('svccfg export thing2') do
      its(:stdout) { is_expected.not_to match(/property5.*glob/) }
    end
  end
end
