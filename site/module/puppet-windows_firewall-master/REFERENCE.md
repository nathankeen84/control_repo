# Reference

<!-- DO NOT EDIT: This document was generated by Puppet Strings -->

## Table of Contents

### Classes

* [`windows_firewall`](#windows_firewall): == Class: windows_firewall  Module to manage the windows firewall and its configured exceptions  === Requirements/Dependencies  Currently ree

### Defined types

* [`windows_firewall::exception`](#windows_firewall--exception): == Define: windows_firewall::exception  This defined type manages exceptions in the windows firewall  === Requirements/Dependencies  Currentl

### Resource types

* [`windowsfirewall`](#windowsfirewall): Puppet type that models Windows Firewall rules

### Data types

* [`Windows_firewall::Port`](#Windows_firewall--Port)

## Classes

### <a name="windows_firewall"></a>`windows_firewall`

== Class: windows_firewall

Module to manage the windows firewall and its configured exceptions

=== Requirements/Dependencies

Currently reequires the puppetlabs/stdlib module on the Puppet Forge in
order to validate much of the the provided configuration.

=== Parameters

[*ensure*]
Control the state of the windows firewall application

[*exceptions*]
Hash of exceptions to be created.

=== Examples

To ensure that windows_firwall is running:

  include windows_firewall

#### Parameters

The following parameters are available in the `windows_firewall` class:

* [`ensure`](#-windows_firewall--ensure)
* [`exceptions`](#-windows_firewall--exceptions)

##### <a name="-windows_firewall--ensure"></a>`ensure`

Data type: `Stdlib::Ensure::Service`



Default value: `'running'`

##### <a name="-windows_firewall--exceptions"></a>`exceptions`

Data type: `Hash`



Default value: `{}`

## Defined types

### <a name="windows_firewall--exception"></a>`windows_firewall::exception`

== Define: windows_firewall::exception

This defined type manages exceptions in the windows firewall

=== Requirements/Dependencies

Currently reequires the puppetlabs/stdlib module on the Puppet Forge in
order to validate much of the the provided configuration.

=== Parameters

[*ensure*]
Control the existence of a rule

[*direction*]
Specifies whether this rule matches inbound or outbound network traffic.

[*action*]
Specifies what Windows Firewall with Advanced Security does to filter network packets that match the criteria specified in this rule.

[*enabled*]
Specifies whether the rule is currently enabled.

[*protocol*]
Specifies that network packets with a matching IP protocol match this rule.

[*remote_ip*]
Specifies remote hosts that can use this rule.

[*local_port*]
Specifies that network packets with matching local IP port numbers matched by this rule.

[*remote_port*]
Specifies that network packets with matching remote IP port numbers matched by this rule.

[*display_name*]
Specifies the rule name assigned to the rule that you want to display. Defaults to the title of the resource.

[*description*]
Provides information about the firewall rule.

[*allow_edge_traversal*]
Specifies that the traffic for this exception traverses an edge device

=== Examples

 Exception for protocol/port:

  windows_firewall::exception { 'WINRM-HTTP-In-TCP':
    ensure       => present,
    direction    => 'in',
    action       => 'allow',
    enabled      => true,
    protocol     => 'TCP',
    local_port   => 5985,
    remote_port  => 'any',
    remote_ip    => '10.0.0.1,10.0.0.2'
    program      => undef,
    display_name => 'Windows Remote Management HTTP-In',
    description  => 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5985]',
  }

 Exception for program path:

  windows_firewall::exception { 'myapp':
    ensure       => present,
    direction    => 'in',
    action       => 'allow',
    enabled      => true,
    program      => 'C:\\myapp.exe',
    display_name => 'My App',
    description  => 'Inbound rule for My App',
  }

#### Parameters

The following parameters are available in the `windows_firewall::exception` defined type:

* [`ensure`](#-windows_firewall--exception--ensure)
* [`direction`](#-windows_firewall--exception--direction)
* [`action`](#-windows_firewall--exception--action)
* [`enabled`](#-windows_firewall--exception--enabled)
* [`protocol`](#-windows_firewall--exception--protocol)
* [`local_port`](#-windows_firewall--exception--local_port)
* [`remote_port`](#-windows_firewall--exception--remote_port)
* [`remote_ip`](#-windows_firewall--exception--remote_ip)
* [`program`](#-windows_firewall--exception--program)
* [`display_name`](#-windows_firewall--exception--display_name)
* [`description`](#-windows_firewall--exception--description)
* [`allow_edge_traversal`](#-windows_firewall--exception--allow_edge_traversal)

##### <a name="-windows_firewall--exception--ensure"></a>`ensure`

Data type: `Enum['present', 'absent']`



Default value: `'present'`

##### <a name="-windows_firewall--exception--direction"></a>`direction`

Data type: `Enum['in', 'out']`



Default value: `'in'`

##### <a name="-windows_firewall--exception--action"></a>`action`

Data type: `Enum['allow', 'block']`



Default value: `'allow'`

##### <a name="-windows_firewall--exception--enabled"></a>`enabled`

Data type: `Boolean`



Default value: `true`

##### <a name="-windows_firewall--exception--protocol"></a>`protocol`

Data type: `Optional[Enum['TCP', 'UDP', 'ICMPv4', 'ICMPv6']]`



Default value: `undef`

##### <a name="-windows_firewall--exception--local_port"></a>`local_port`

Data type: `Windows_firewall::Port`



Default value: `undef`

##### <a name="-windows_firewall--exception--remote_port"></a>`remote_port`

Data type: `Windows_firewall::Port`



Default value: `undef`

##### <a name="-windows_firewall--exception--remote_ip"></a>`remote_ip`

Data type: `Optional[String]`



Default value: `undef`

##### <a name="-windows_firewall--exception--program"></a>`program`

Data type: `Optional[Stdlib::Windowspath]`



Default value: `undef`

##### <a name="-windows_firewall--exception--display_name"></a>`display_name`

Data type: `String[0, 255]`



Default value: `$title`

##### <a name="-windows_firewall--exception--description"></a>`description`

Data type: `Optional[String[1, 255]]`



Default value: `undef`

##### <a name="-windows_firewall--exception--allow_edge_traversal"></a>`allow_edge_traversal`

Data type: `Boolean`



Default value: `false`

## Resource types

### <a name="windowsfirewall"></a>`windowsfirewall`

Puppet type that models Windows Firewall rules

#### Properties

The following properties are available in the `windowsfirewall` type.

##### `allow_inbound_rules`

Allow inbound rules

##### `allow_local_firewall_rules`

Allow local firewall rules

##### `allow_local_ipsec_rules`

Allow local IPsec rules

##### `allow_unicast_response_to_multicast`

Allow unicast response to multicast

##### `allow_user_apps`

Allow user apps

##### `allow_user_ports`

Allow user ports

##### `default_inbound_action`

Default inbound rules for the zone

##### `default_outbound_action`

Default outbound rules for the zone

##### `disabled_interface_aliases`

Disabled interface aliases

##### `enable_stealth_mode_for_ipsec`

Enable stealth mode for IPsec

##### `ensure`

Valid values: `present`, `absent`

The basic property that the resource should be in.

Default value: `present`

##### `log_allowed`

Log allowed

##### `log_blocked`

Log blocked

##### `log_file_name`

Log file name

##### `log_ignored`

Log ignored

##### `log_max_size_kilobytes`

Log max size - in kilobytes

##### `notify_on_listen`

Notify on listen

#### Parameters

The following parameters are available in the `windowsfirewall` type.

* [`name`](#-windowsfirewall--name)
* [`provider`](#-windowsfirewall--provider)

##### <a name="-windowsfirewall--name"></a>`name`

Valid values: `domain`, `public`, `private`

namevar

Windows firewall zones - either 'domain', 'public', or 'private'

##### <a name="-windowsfirewall--provider"></a>`provider`

The specific backend to use for this `windowsfirewall` resource. You will seldom need to specify this --- Puppet will
usually discover the appropriate provider for your platform.

## Data types

### <a name="Windows_firewall--Port"></a>`Windows_firewall::Port`

The Windows_firewall::Port data type.

Alias of `Optional[Variant[Stdlib::Port, Enum['any'], Pattern[/\A[1-9]{1}\Z|[1-9]{1}[0-9,-]*[0-9]{1}\Z/]]]`
