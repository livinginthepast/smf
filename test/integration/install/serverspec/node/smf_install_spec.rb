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
