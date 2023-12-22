# frozen_string_literal: true

require 'spec_helper'

describe 'postgresql::server::postgis' do
  include_examples 'Debian 11'
  let :pre_condition do
    "class { 'postgresql::server': }"
  end

  describe 'with parameters' do
    let(:params) do
      {
        package_name: 'mypackage',
        package_ensure: 'absent'
      }
    end

    it 'creates package with correct params' do
      expect(subject).to contain_package('postgresql-postgis').with(ensure: 'absent',
                                                                    name: 'mypackage',
                                                                    tag: 'puppetlabs-postgresql')
    end
  end

  describe 'with no parameters' do
    it 'creates package with postgresql tag' do
      expect(subject).to contain_package('postgresql-postgis').with(tag: 'puppetlabs-postgresql')
    end
  end
end
