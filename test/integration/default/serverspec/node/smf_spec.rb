require 'spec_helper'

context 'Added services' do
  describe service('thing') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end
  describe service('thing2') do
    it { is_expected.not_to be_enabled }
    it { is_expected.not_to be_running }
  end
end
context 'Service properties' do
  describe command('svccfg export thing2') do
    its(:stdout) { is_expected.to match(/property1.*true/) }
    its(:stdout) { is_expected.to match(/value_node.*complex modified value/) }
    its(:stdout) { is_expected.to match(/value_node.*basic/) }
 end
  describe command('svccfg export modify_name-service-cache') do
    its(:stdout) { is_expected.to match(/per_user_nscd_time_to_live.*240/) }
 end
end

# service with deleted property value
# service with deleted property
