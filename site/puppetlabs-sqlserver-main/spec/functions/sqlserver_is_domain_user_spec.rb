# frozen_string_literal: true

require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'lib/puppet_x/sqlserver/server_helper'))

RSpec.describe 'sqlserver_is_domain_or_local_user?' do
  shared_examples 'return the value' do
    it {
      allow(Facter).to receive(:value).with(anything)
      allow(Facter).to receive(:value).with(:hostname).and_return('mybox')
      expect(scope.function_sqlserver_is_domain_or_local_user([user])).to eq(expected_value)
    }
  end

  ['mysillyuser', 'mybox\localuser'].each do |user|
    describe "when calling with a local user #{user}" do
      it_behaves_like 'return the value' do
        let(:expected_value) { false }
        let(:user) { user }
      end
    end
  end

  ['NT Authority\IISUSR', 'NT Service\ManiacUser', 'nt service\mixMaxCase'].each do |user|
    describe "when calling with a system account #{user}" do
      it_behaves_like 'return the value' do
        let(:user) { user }
        let(:expected_value) { false }
      end
    end
  end

  describe 'when calling with a domain account \'nexus\user\'' do
    it_behaves_like 'return the value' do
      let(:user) { 'nexus\user' }
      let(:expected_value) { true }
    end
  end
end
