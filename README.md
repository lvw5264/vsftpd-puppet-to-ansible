Puppet module to install and configure vsftpd created by Lawrence Wu.

It's best to use existing vsftpd modules like simp-vsftpd; this is more of an example to demonstrate:

1. [Conversion of a traditional Puppet 2 module to Puppet 6 hieradata.](https://github.com/lvw5264/vsftpd-puppet-to-ansible/commit/7136b4d616b1efdbc338b6bb387d757269125feb)
2. [Puppet to Ansible collection roles conversion](https://github.com/lvw5264/vsftpd-puppet-to-ansible/commit/88148c85ae8e3c2550f83275f4b8c3fb7a74dec9) in [the `ansible/` folder](https://github.com/lvw5264/vsftpd-puppet-to-ansible/tree/main/ansible) for a direct comparison of how this Puppet 6 code corresponds, and how it contrasts

---

## What the module does

| Step | Resource |
|---|---|
| Install the package | `package { 'vsftpd': ensure => installed }` |
| Write the config file | `file { '/etc/vsftpd.conf': content => template('vsftpd/vsftpd.conf.erb') }` |
| Start and enable the service | `service { 'vsftpd': ensure => running, enable => true }` |

All three resources are managed inside a single `class vsftpd`. Setting `$ensure => 'absent'` reverses the order: stop -> disable -> remove config -> uninstall package.

---

## Parameters

Defaults are defined in `data/common.yaml` via Puppet 6 hieradata. They can be overridden at any hierarchy level (per-node, per-role, per-datacenter, etc.).

| Parameter | Type | Default | Description |
|---|---|---|---|
| `ensure` | `Enum['present', 'absent']` | `'present'` | Whether to install or uninstall |
| `package_name` | `String[1]` | `'vsftpd'` | OS package name |
| `config_path` | `Stdlib::Absolutepath` | `'/etc/vsftpd.conf'` | Path to vsftpd config file |
| `service_name` | `String[1]` | `'vsftpd'` | Service unit name |
| `service_ensure` | `Enum['running', 'stopped']` | `'running'` | Desired service state |
| `service_enable` | `Boolean` | `true` | Whether to enable at boot |
| `anonymous_enable` | `Boolean` | `false` | Allow anonymous FTP access |
| `local_enable` | `Boolean` | `true` | Allow local users to log in |
| `write_enable` | `Boolean` | `true` | Allow write commands |
| `local_umask` | `String[1]` | `'022'` | Umask for local users |
| `dirmessage_enable` | `Boolean` | `true` | Show directory messages |
| `use_localtime` | `Boolean` | `true` | Use local time instead of GMT |
| `xferlog_enable` | `Boolean` | `true` | Enable transfer logging |
| `connect_from_port_20` | `Boolean` | `true` | Use port 20 for data |
| `chroot_local_user` | `Boolean` | `true` | Chroot local users to home |
| `secure_chroot_dir` | `Stdlib::Absolutepath` | `'/var/run/vsftpd/empty'` | Empty dir for non-chroot sessions |
| `pam_service_name` | `String[1]` | `'vsftpd'` | PAM service name |
| `ssl_enable` | `Boolean` | `false` | Enable SSL/TLS |
| `ssl_ciphers` | `String[1]` | `'HIGH'` | Allowed SSL ciphers |
| `rsa_cert_file` | `Optional[Stdlib::Absolutepath]` | `undef` | Path to SSL certificate |
| `rsa_private_key_file` | `Optional[Stdlib::Absolutepath]` | `undef` | Path to SSL private key |

---

## Template

The config file is generated from `templates/vsftpd.conf.erb`. Boolean parameters are rendered as `YES`/`NO`, and the two SSL file parameters are only emitted when set (via `<% if @rsa_cert_file -%>` guards):

```erb
anonymous_enable=<%= @anonymous_enable ? 'YES' : 'NO' %>
local_enable=<%= @local_enable ? 'YES' : 'NO' %>
chroot_local_user=<%= @chroot_local_user ? 'YES' : 'NO' %>
<% if @rsa_cert_file -%>
rsa_cert_file=<%= @rsa_cert_file %>
<% end -%>
ssl_enable=<%= @ssl_enable ? 'YES' : 'NO' %>
ssl_ciphers=<%= @ssl_ciphers %>
```

A handful of hard-coded lines complement the template variables:

```
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
```

---

## Usage

### Install with defaults

```puppet
include vsftpd
```

Or via hieradata in your control repository:

```yaml
classes:
  - vsftpd
```

### Override parameters in Puppet code

```puppet
class { 'vsftpd':
  ssl_enable             => true,
  rsa_cert_file          => '/etc/pki/tls/certs/vsftpd.pem',
  rsa_private_key_file   => '/etc/pki/tls/private/vsftpd.key',
}
```

### Override parameters in hieradata

```yaml
vsftpd::ensure: absent
vsftpd::ssl_enable: true
vsftpd::rsa_cert_file: /etc/pki/tls/certs/vsftpd.pem
vsftpd::rsa_private_key_file: /etc/pki/tls/private/vsftpd.key
```

Its preferable to use hieradata, as it keeps parameter values out of code and allows different values per environment/node/role via the hierarchy.

### Uninstall

```yaml
vsftpd::ensure: absent
```

This stops the service, disables it, removes the config file, then uninstalls the package - the reverse of install order.

---

## File layout

```
manifests/
  init.pp          # main class definition
data/
  common.yaml      # default parameter values (hieradata level 5)
templates/
  vsftpd.conf.erb  # config file template
hiera.yaml         # hierarchy configuration
metadata.json      # module metadata and dependencies
```

---

## Dependencies

- `puppetlabs/stdlib` (≥ 4.13.0) - provides `Stdlib::Absolutepath` type alias.
