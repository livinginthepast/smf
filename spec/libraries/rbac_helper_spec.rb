require 'spec_helper'
require_relative '../../libraries/helper'
require_relative '../../libraries/rbac_helper'

RSpec.describe SMFManifest::RBACHelper do
  subject(:rbac_helper) { SMFManifest::RBACHelper.new(node, resource) }
  let(:node) { double }
  let(:resource) { double(name: name, authorization_name: authorization_name) }

  let(:name) { 'service-name' }
  let(:authorization_name) { 'junk' }

  describe '#authorization' do
    let(:authorization_name) { 'my_stuff' }
    it 'is the authorization_name appended to a prefix' do
      expect(rbac_helper.authorization).to eq('solaris.smf.manage.my_stuff')
    end
  end

  describe '#current_authorization' do
    it 'is the action_authorization service property of the installed service' do
      shell_out_double = double(stdout: "solaris.smf.manage.mr_t\n")
      allow(rbac_helper).to receive(:shell_out).with('svcprop -p general/action_authorization service-name') {
        shell_out_double
      }
      expect(rbac_helper.current_authorization).to eq('solaris.smf.manage.mr_t')
    end
  end

  describe '#value_authorization' do
    let(:authorization_name) { 'my_stuff' }
    it 'is the authorization_name appended to a prefix' do
      expect(rbac_helper.value_authorization).to eq('solaris.smf.value.my_stuff')
    end
  end

  describe '#current_value_authorization' do
    it 'is the action_authorization service property of the installed service' do
      shell_out_double = double(stdout: "solaris.smf.value.mr_t\n")
      allow(rbac_helper).to receive(:shell_out).with('svcprop -p general/value_authorization service-name') {
        shell_out_double
      }
      expect(rbac_helper.current_value_authorization).to eq('solaris.smf.value.mr_t')
    end
  end

  describe '#authorization_set?' do
    context 'when authorizations match' do
      before do
        allow(rbac_helper).to receive(:current_authorization).and_return('solaris.smf.manage.my-stuff')
        allow(rbac_helper).to receive(:authorization).and_return('solaris.smf.manage.my-stuff')
      end
      it 'is true' do
        expect(rbac_helper.authorization_set?).to be true
      end
    end

    context 'when authorizations differ' do
      before do
        allow(rbac_helper).to receive(:current_authorization).and_return('solaris.smf.manage.your-stuff')
        allow(rbac_helper).to receive(:authorization).and_return('solaris.smf.manage.my-stuff')
      end
      it 'is false' do
        expect(rbac_helper.authorization_set?).to be false
      end
    end
  end
end
