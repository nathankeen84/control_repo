# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'Purge' do
  let(:acl_manifest) do
    <<-MANIFEST
      file { "#{target_parent}":
        ensure => directory
      }

      file { "#{target}":
        ensure  => directory,
        require => File['#{target_parent}']
      }

      user { "#{user_id1}":
        ensure     => present,
        groups     => 'Users',
        managehome => true,
        password   => "L0v3Pupp3t!"
      }

      user { "#{user_id2}":
        ensure     => present,
        groups     => 'Users',
        managehome => true,
        password   => "L0v3Pupp3t!"
      }

      acl { "#{target}":
        permissions  => [
          { identity => '#{user_id1}', rights => ['full'] },
        ],
      }
    MANIFEST
  end

  let(:acl_manifest_purge) do
    <<-MANIFEST
      acl { "#{target}":
        purge        => 'true',
        permissions  => [
          { identity => '#{user_id2}', rights => ['full'] },
        ],
      }
    MANIFEST
  end

  context 'Only Purge Explicit Permissions from Directory with Inheritance' do
    random_username = generate_random_username
    let(:target) { 'c:/temp/purge_exp_inherit' }
    let(:user_id1) { 'bob' }
    let(:user_id2) { random_username }

    let(:verify_acl_command) { "icacls #{target}" }
    let(:acl_regex_user_id1) { %r{.*\\bob:\(OI\)\(CI\)\(F\)} }
    let(:acl_regex_user_id2) { %r{.*\\#{user_id2}:\(OI\)\(CI\)\(F\)} }

    it 'applies manifest' do
      acl_idempotent_apply(acl_manifest)
    end

    it 'verifies ACL rights' do
      run_shell(verify_acl_command) do |result|
        expect(result.stdout).to match(%r{#{acl_regex_user_id1}})
      end
    end

    it 'executes purge' do
      acl_idempotent_apply(acl_manifest_purge)
    end

    it 'verifies ACL rights (post-purge)' do
      run_shell(verify_acl_command) do |result|
        expect(result.stdout).not_to match(%r{#{acl_regex_user_id1}})
        expect(result.stdout).to match(%r{#{acl_regex_user_id2}})
      end
    end
  end
end
