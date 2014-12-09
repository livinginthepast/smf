# encoding: utf-8
# Cookbook Name:: smf
# spec:: properties
#

require 'rspec_helper'
include SMFProperties
include Chef::Mixin::ShellOut
describe 'SMFproperty class setting properties' do

  let(:shellout) { double('shellout') }
  before(:each) { read_xml }

  context 'on single valued property' do
    describe 'with current single value' do
      pg_setting = { config: { search: 'mydomain.net' } }
      it 'should not change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq false
      end
    end
    describe 'with new single value' do
      pg_setting = { config: { search: 'new_domain.net' } }
      it 'should change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq true
      end
    end
    describe 'with single added property' do
      pg_setting = { config: { newsearch: 'new_domain.net' } }
      it 'should change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq true
      end
    end
  end

  context 'on multi valued property' do
    describe 'with embedded blanks in the value' do
      pg_setting = { config: { newsearch: '("complex value" "new_domain.net")' } }
      it 'should change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq true
      end
    end
    describe 'with same number of new multiple values' do
      pg_setting = { config: { nameserver: '(10.1.2.1 10.1.2.2 10.1.2.3)' } }
      it 'should change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq true
      end
    end
    describe 'with fewer new multiple values' do
      pg_setting = { config: { nameserver: '(10.1.1.1 10.1.1.2)' } }
      it 'should not change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq true
      end
    end
    describe 'with more new multiple values' do
      pg_setting = { config: { nameserver: '(10.1.1.1 10.1.1.2 10.1.1.3 10.1.1.4)' } }
      it 'should change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq true
      end
    end
    describe 'with current values' do
      pg_setting = { config: { nameserver: '(10.1.1.1 10.1.1.2 10.1.1.3)' } }
      it 'should not change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq false
      end
    end
    describe 'with current values in a different order' do
      pg_setting = { config: { nameserver: '(10.1.1.3 10.1.1.2 10.1.1.1)' } }
      it 'should change the value' do
        properties = Changes.new(pg_setting)
        expect(properties.set('network/dns/client')).to eq true
      end
    end

  end
end

describe 'Removing properties' do

  let(:shellout) { double('shellout') }
  before(:each) { read_xml }
  context 'from single valued properties' do
    describe 'Delete an existing property value' do
      pg_setting = { config: { nameserver: '(10.1.1.1)' } }
      it 'should delete the value' do
        properties = Changes.new(pg_setting)
        expect(properties.delete_values('network/dns/client')).to eq true
      end
    end
    describe 'Delete a missing property value' do
      pg_setting = { config: { nameserver: '(10.1.1.5)' } }
      it 'should not delete the value' do
        properties = Changes.new(pg_setting)
        expect(properties.delete_values('network/dns/client')).to eq false
      end
    end
    describe 'Delete a property value from a missing property' do
      pg_setting = { config: { notdefined_property: '(10.1.1.5)' } }
      it 'should not delete the value' do
        properties = Changes.new(pg_setting)
        expect(properties.delete_values('network/dns/client')).to eq false
      end
    end
  end
  context 'from multi valued properties' do
    describe 'Delete multiple existing property values' do
      pg_setting = { config: { nameserver: '(10.1.1.3 10.1.1.2 10.1.1.1)' } }
      it 'should delete the values' do
        properties = Changes.new(pg_setting)
        expect(properties.delete_values('network/dns/client')).to eq true
      end
    end
    describe 'Delete a missing property' do
      pg_setting = { config: { net_address_not_there: '(10.1.1.3 10.1.1.2 10.1.1.1)' } }
      it 'should not delete the property' do
        properties = Changes.new(pg_setting)
        expect(properties.delete('network/dns/client')).to eq false
      end
    end
    describe 'Delete a property ' do
      pg_setting = { config: { nameserver: 'dummy' } }
      it 'should delete the property' do
        properties = Changes.new(pg_setting)
        expect(properties.delete('network/dns/client')).to eq true
      end
    end
  end

end

def read_xml
  Mixlib::ShellOut.stub(:new).and_return(shellout)
  shellout.stub(:stdout).and_return(dnsxml)
  shellout.stub(:run_command).and_return(nil)
  shellout.stub(:live_stream).and_return(nil)
  shellout.stub(:live_stream=).and_return(nil)
  shellout.stub(:error!).and_return(nil)
end

def dnsxml
  "<?xml version='1.0'?>
<!DOCTYPE service_bundle SYSTEM '/usr/share/lib/xml/dtd/service_bundle.dtd.1'>
<service_bundle type='manifest' name='export'>
  <service name='network/dns/client' type='service' version='0'>
    <create_default_instance enabled='true'/>
    <single_instance/>
    <dependency name='filesystem' grouping='require_all' restart_on='none' type='service'>
      <service_fmri value='svc:/system/filesystem/root'/>
      <service_fmri value='svc:/system/filesystem/usr'/>
      <service_fmri value='svc:/system/filesystem/minimal'/>
    </dependency>
    <property_group name='general' type='framework'>
      <propval name='action_authorization' type='astring' value='solaris.smf.manage.name-service.dns.client'/>
      <propval name='value_authorization' type='astring' value='solaris.smf.manage.name-service.dns.client'/>
    </property_group>
    <property_group name='startd' type='framework'>
      <propval name='duration' type='astring' value='transient'/>
    </property_group>
    <property_group name='config' type='application'>
      <propval name='value_authorization' type='astring' value='solaris.smf.value.name-service.dns.client'/>
      <propval name='search' type='astring' value='mydomain.net'/>
      <property name='nameserver' type='net_address'>
        <net_address_list>
          <value_node value='10.1.1.1'/>
          <value_node value='10.1.1.2'/>
          <value_node value='10.1.1.3'/>
        </net_address_list>
      </property>
    </property_group>
    <property_group name='sysconfig' type='sysconfig'>
      <propval name='group' type='astring' value='naming_services'/>
      <property name='config_properties' type='astring'>
        <astring_list>
          <value_node value='sc_dns_nameserver:config/nameserver'/>
          <value_node value='sc_dns_search:config/search'/>
        </astring_list>
      </property>
    </property_group>
    <stability value='Unstable'/>
    <template>
      <common_name>
        <loctext xml:lang='C'>DNS resolver</loctext>
      </common_name>
      <documentation>
        <manpage title='resolver' section='3RESOLV' manpath='/usr/share/man'/>
      </documentation>
    </template>
  </service>
</service_bundle>"
end
