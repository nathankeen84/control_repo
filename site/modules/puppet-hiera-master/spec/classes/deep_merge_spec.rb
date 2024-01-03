# frozen_string_literal: false

require 'spec_helper'
require 'puppet'

describe 'hiera::deep_merge' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      context 'merge_behavior => deep' do
        let(:pre_condition) do
          'class { "hiera": merge_behavior => "deep", manage_deep_merge_package => true }'
        end

        it { is_expected.to compile }
        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_package('deep_merge').with(
            'ensure'  => 'installed'
          )
        end

        it { is_expected.to contain_hiera__install('deep_merge') }
      end

      context 'merge_behavior => deeper' do
        let(:pre_condition) do
          'class { "hiera": merge_behavior => "deep", manage_deep_merge_package => true }'
        end

        it do
          is_expected.to contain_package('deep_merge').with(
            'ensure'  => 'installed'
          )
        end

        it { is_expected.to contain_hiera__install('deep_merge') }
      end
    end
  end
end
