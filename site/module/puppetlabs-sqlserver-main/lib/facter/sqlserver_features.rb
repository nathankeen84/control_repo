# frozen_string_literal: true

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'puppet_x/sqlserver/features'))

Facter.add(:sqlserver_features) do
  confine osfamily: :windows

  setcode do
    PuppetX::Sqlserver::Features.features
  end
end
