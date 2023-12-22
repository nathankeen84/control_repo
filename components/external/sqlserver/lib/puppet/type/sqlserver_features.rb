# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'property/sqlserver_login'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x/sqlserver/server_helper'))

Puppet::Type.newtype(:sqlserver_features) do
  ensurable

  newparam(:name, namevar: true) do
    desc 'Due to our prefetch and unaware of what name the user will provide we munge the value to meet our expecations.'
    munge do |_value|
      'Generic Features'
    end
  end

  newparam(:source) do
    desc 'Location of the source files.'
  end

  newparam(:windows_feature_source) do
    desc 'Specify the location of the Windows Feature source files.  This may be needed to install the .Net Framework.
          See https://support.microsoft.com/en-us/kb/2734782 for more information.'
  end

  newparam(:pid) do
    desc 'Specify the SQL Server product key to configure which edition you would like to use.'
  end

  newparam(:is_svc_account, parent: Puppet::Property::SqlserverLogin) do
    desc 'Either domain user name or system account. Defaults to "NT AUTHORITY\NETWORK SERVICE"'
  end

  newparam(:is_svc_password) do
    desc 'Password for domain user.'
  end

  newproperty(:features, array_matching: :all) do
    desc "Specifies features to install, uninstall, or upgrade. The list of top-level features include
         BC, Conn, SSMS, ADV_SSMS, SDK, IS and MDS. The 'Tools' feature is deprecated.  Instead specify 'BC', 'SSMS', 'ADV_SSMS', 'Conn', and 'SDK' explicitly."
    newvalues(:Tools, :BC, :Conn, :SSMS, :ADV_SSMS, :SDK, :IS, :MDS, :BOL, :DREPLAY_CTLR, :DREPLAY_CLT, :DQC)
    munge do |value|
      if PuppetX::Sqlserver::ServerHelper.is_super_feature(value)
        Puppet.deprecation_warning("Using #{value} is deprecated for features in sql_features resources")
        PuppetX::Sqlserver::ServerHelper.get_sub_features(value).map(&:to_s)
      else
        value
      end
    end
  end

  newparam(:install_switches) do
    desc 'A hash of switches you want to pass to the installer'
    validate do |value|
      raise ArgumentError, _('install_switch must be in the form of a Hash') unless value.is_a?(Hash)
    end
  end

  def validate
    self[:features] = self[:features].flatten.sort.uniq if set?(:features)
    # IS_SVC_ACCOUNT validation
    return unless set?(:features) && self[:features].include?('IS')
    return unless set?(:is_svc_account) || set?(:is_svc_password)

    validate_user_password_required(:is_svc_account, :is_svc_password)
  end

  def domain_or_local_user?(user)
    PuppetX::Sqlserver::ServerHelper.is_domain_or_local_user?(user, Facter.value(:hostname))
  end

  def validate_user_password_required(account, pass)
    raise("User #{account} is required") unless set?(account)
    return unless domain_or_local_user?(self[account]) && self[pass].nil?

    raise("#{pass} required when using domain account")
  end

  def set?(key)
    !self[key].nil? && !self[key].empty?
  end
end
