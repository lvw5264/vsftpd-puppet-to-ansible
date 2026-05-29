Puppet module to install and configure vsftpd created by Lawrence Wu. 

Its best to use existing vsftpd modules like simp-vsftpd, this is more of an example to demonstrate:

1. [Conversion of a traditional Puppet 2 module to Puppet 6 hieradata.](https://github.com/lvw5264/vsftpd-puppet-to-ansible/commit/7136b4d616b1efdbc338b6bb387d757269125feb)
2. [Puppet to Ansible collection roles conversion](https://github.com/lvw5264/vsftpd-puppet-to-ansible/commit/88148c85ae8e3c2550f83275f4b8c3fb7a74dec9) in [the `ansible/` folder](https://github.com/lvw5264/vsftpd-puppet-to-ansible/tree/main/ansible) for a direct comparison of how this Puppet 6 code corresponds, and how it contrasts

## Puppet

### Installing the Module

To use this module, define it in to your `Puppetfile`:

```ruby
mod 'vsftpd', :git => 'https://github.com/yourusername/puppet-vsftpd.git'
```

Then run the appropriate command to install the module.

Finally, declare in puppet class code as follows:

```
include vsftpd
```

Additional parameters can be set with a `class` definition if necessary.

Or in controlrepo hieradata:

```
---
classes:
  - vsftpd
```
