# encoding: utf-8
# Cookbook Name:: smf
# spec:: properties
#

require 'spec_helper'
require_relative '../../libraries/properties'

RSpec.describe SMFProperties::Changes do
  include PropertiesHelper

  describe 'SMFproperty class setting properties' do
    let(:shellout) { double('shellout') }
    before(:each) { read_xml }

    context 'on single valued property' do
      describe 'with current single value' do
        pg_setting = { config: { search: 'mydomain.net' } }
        it 'should not change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq false
        end
      end
      describe 'with new single value' do
        pg_setting = { config: { search: 'new_domain.net' } }
        it 'should change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq true
        end
      end
      describe 'with single added property' do
        pg_setting = { config: { newsearch: 'new_domain.net' } }
        it 'should change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq true
        end
      end
      describe 'with a single value property seperated by spaces' do
        pg_setting = { config: { host: '("dns files")' } }
        it 'should change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq true
        end
      end
      describe 'reset with a single value property seperated by spaces' do
        pg_setting = { config: { host: '("files dns")' } }
        it 'should not change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq false
        end
      end
      describe 'set a null value' do
        pg_setting = { config: { option: '' } }
        it 'should change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq true
        end
      end
      describe 'reset a null value' do
        pg_setting = { config: { nulloption: '' } }
        it 'should not change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq false
        end
      end
    end

    context 'on multi valued property' do
      describe 'with embedded blanks in the value' do
        pg_setting = { config: { newsearch: '("complex value" "new_domain.net")' } }
        it 'should change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq true
        end
      end
      describe 'with same number of new multiple values' do
        pg_setting = { config: { nameserver: '(10.1.2.1 10.1.2.2 10.1.2.3)' } }
        it 'should change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq true
        end
      end
      describe 'with fewer new multiple values' do
        pg_setting = { config: { nameserver: '(10.1.1.1 10.1.1.2)' } }
        it 'should not change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq true
        end
      end
      describe 'with more new multiple values' do
        pg_setting = { config: { nameserver: '(10.1.1.1 10.1.1.2 10.1.1.3 10.1.1.4)' } }
        it 'should change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq true
        end
      end
      describe 'with current values' do
        pg_setting = { config: { nameserver: '(10.1.1.1 10.1.1.2 10.1.1.3)' } }
        it 'should not change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq false
        end
      end
      describe 'with quoted current values' do
        pg_setting = { config: { nameserver: '("10.1.1.1" "10.1.1.2" "10.1.1.3")' } }
        it 'should not change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.set('network/dns/client')).to eq false
        end
      end
      describe 'with current values in a different order' do
        pg_setting = { config: { nameserver: '(10.1.1.3 10.1.1.2 10.1.1.1)' } }
        it 'should change the value' do
          properties = SMFProperties::Changes.new(pg_setting)
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
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.delete_values('network/dns/client')).to eq true
        end
      end
      describe 'Delete a missing property value' do
        pg_setting = { config: { nameserver: '(10.1.1.5)' } }
        it 'should not delete the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.delete_values('network/dns/client')).to eq false
        end
      end
      describe 'Delete a property value from a missing property' do
        pg_setting = { config: { notdefined_property: '(10.1.1.5)' } }
        it 'should not delete the value' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.delete_values('network/dns/client')).to eq false
        end
      end
    end
    context 'from multi valued properties' do
      describe 'Delete multiple existing property values' do
        pg_setting = { config: { nameserver: '(10.1.1.3 10.1.1.2 10.1.1.1)' } }
        it 'should delete the values' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.delete_values('network/dns/client')).to eq true
        end
      end
      describe 'Delete a missing property' do
        pg_setting = { config: { net_address_not_there: '(10.1.1.3 10.1.1.2 10.1.1.1)' } }
        it 'should not delete the property' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.delete('network/dns/client')).to eq false
        end
      end
      describe 'Delete a property ' do
        pg_setting = { config: { nameserver: 'dummy' } }
        it 'should delete the property' do
          properties = SMFProperties::Changes.new(pg_setting)
          expect(properties.delete('network/dns/client')).to eq true
        end
      end
    end
  end
end
