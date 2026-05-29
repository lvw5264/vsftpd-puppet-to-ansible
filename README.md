Puppet module to install and configure vsftpd created by Lawrence Wu. 

Its best to use existing vsftpd modules like simp-vsftpd, this is more of an example to demonstrate conversion of a traditional Puppet 2 module to Puppet 6 hieradata.

You can see an ansible collection roles conversion in the `ansible/` folder for a direct comparison of how this Puppet 6 code corresponds quite similarly.

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

Or in controlrepo hieradata:

```
---
classes:
  - vsftpd
```
