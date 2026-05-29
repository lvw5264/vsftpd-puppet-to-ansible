# vsftpd - Ansible collection

I ported from the puppet module in the parent directory to this ansible collection. We must first take in and accept the differences between puppet and ansible. They aren't designed exactly the same, but they were inspired by each other. And as such there are things that one does better than the other, especially puppet's ensures.

In particular, since a lot of documentation online has been produced about Puppet just as much as with Ansible, this makes it easy for AI agents to automate. You may want to have them follow these sorts of methodologies:

https://www.reddit.com/r/Puppet/comments/1sk988l/helping_with_puppettoansible_migrations_a_local/

https://github.com/pavelux00x/puppet-to-ansible

https://old.reddit.com/r/Puppet/comments/1nyixhy/puppet_or_ansible/


---

## Structure

| Concern | Puppet | Ansible |
|---|---|---|
| Module/collection metadata | `metadata.json` | `galaxy.yml` |
| Parameter defaults | `data/common.yaml` under `vsftpd::` keys | `roles/vsftpd/defaults/main.yml` as flat `vsftpd_` vars |
| Main logic | `manifests/init.pp` | `roles/vsftpd/tasks/main.yml` |
| Template | `templates/vsftpd.conf.erb` | `roles/vsftpd/templates/vsftpd.conf.j2` |
| Service restart | `notify => Service[$service_name]` + `subscribe => File[$config_path]` inside class | dedicated `handlers/main.yml` + `notify: restart vsftpd` in task |
| Invocation | `include vsftpd` in Puppet manifest or class in hieradata | `roles:` section in a playbook (or `include_role`) |

---

## Variable naming

Puppet uses a namespaced `::` separator that matches the class:

**Puppet `data/common.yaml`**                                      | **Ansible `defaults/main.yml`**
-------------------------------------------------------------------|--------------------------------
`vsftpd::ensure: 'present'`                                        | `vsftpd_ensure: present`
`vsftpd::anonymous_enable: false`                                  | `vsftpd_anonymous_enable: false`
`vsftpd::rsa_cert_file: null`                                      | `vsftpd_rsa_cert_file: null`

Puppet references these as `$ensure`, `$anonymous_enable` inside the class. Ansible references them as `{{ vsftpd_ensure }}`, `{{ vsftpd_anonymous_enable }}` everywhere.

---

## Conditional install/uninstall

**Puppet** uses a single class with an `if/else` on `$ensure`:

```puppet
class vsftpd (Enum['present', 'absent'] $ensure = 'present') {
  if $ensure == 'absent' {
    service { $service_name: 
      ensure => stopped,
      enable => false 
    }
    file { $config_path:  
      ensure => absent
    }
    package { $package_name:
      ensure => absent
    }
  } else {
    package { $package_name:
      ensure => installed 
    }
    file   { $config_path:
      ensure => file, 
      content => template('vsftpd/vsftpd.conf.erb') 
    }
    service { $service_name:
      ensure => running,
      enable => true 
    }
  }
}
```

**Ansible** uses `when` conditionals on separate blocks:

```yaml
---
- name: Ensure vsftpd is {{ vsftpd_ensure }}
  block:
    - name: Uninstall vsftpd
      when: vsftpd_ensure == 'absent'
      block:
        - name: Stop and disable vsftpd service
          service:
            name: "{{ vsftpd_service_name }}"
            state: stopped
            enabled: false

        - name: Remove vsftpd config file
          file:
            path: "{{ vsftpd_config_path }}"
            state: absent

        - name: Uninstall vsftpd package
          package:
            name: "{{ vsftpd_package_name }}"
            state: absent

    - name: Install vsftpd
      when: vsftpd_ensure == 'present'
      block:
        - name: Install vsftpd package
          package:
            name: "{{ vsftpd_package_name }}"
            state: present

        - name: Configure vsftpd
          template:
            src: vsftpd.conf.j2
            dest: "{{ vsftpd_config_path }}"
            owner: root
            group: root
            mode: '0644'
          notify: restart vsftpd

        - name: Ensure vsftpd service is running
          service:
            name: "{{ vsftpd_service_name }}"
            state: "{{ vsftpd_service_state }}"
            enabled: "{{ vsftpd_service_enabled }}"

```

Key differences:

- Puppet's `if/else` is a language construct; Ansible uses `when:` as a task/block attribute.
- Puppet ties `ensure => file` to `content => template()` in one resource; Ansible splits this into the `template` module.
- Puppet handles ordering with `require`/`subscribe` meta-parameters; Ansible relies on task list order and `notify`.

---

## Template comparison

| Feature | Puppet ERB (`.erb`) | Ansible Jinja2 (`.j2`) |
|---|---|---|
| Output a variable | `<%= @var %>` | `{{ var }}` |
| Boolean -> YES/NO | `<%= @bool ? 'YES' : 'NO' %>` | `{{ 'YES' if bool else 'NO' }}` |
| Conditional block | `<% if @var -%>...<% end -%>` | `{% if var is not none %}...{% endif %}` |
| Scoping | `@var` refers to the class scope | bare variable name (prefixed `vsftpd_`) |

Example - optional RSA cert file:

```erb
<% if @rsa_cert_file -%>
rsa_cert_file=<%= @rsa_cert_file %>
<% end -%>
```

```jinja2
{% if vsftpd_rsa_cert_file is not none %}
rsa_cert_file={{ vsftpd_rsa_cert_file }}
{% endif %}
```

---

## Type safety

| Feature | Puppet | Ansible |
|---|---|---|
| Type enforcement | Built-in (`Enum['present','absent']`, `Boolean`, `Stdlib::Absolutepath`, `Optional[...]`) | None at the language level - rely on docs, testing, or schema (via `meta/runtime.yml`) |
| Undefined/null | `undef` | `null` (YAML) / `None` (Jinja2) |

Puppet validates parameters at catalog compilation. Ansible applies whatever value is provided; invalid values surface at runtime.

---

## Service restart on config change

**Puppet** uses resource chaining inside the same class body:

```puppet
file { $config_path:
  content => template('vsftpd/vsftpd.conf.erb'),
  notify  => Service[$service_name],
}
service { $service_name:
  subscribe => File[$config_path],
}
```

**Ansible** uses a handler referenced by name:

```yaml
# tasks/main.yml
- template:
    src: vsftpd.conf.j2
    dest: "{{ vsftpd_config_path }}"
  notify: restart vsftpd

# handlers/main.yml
- name: restart vsftpd
  service:
    name: "{{ vsftpd_service_name }}"
    state: restarted
```

The handler only fires when the template task reports a change (i.e. the file actually differed).

---

## How to use

### Install the collection

```bash
ansible-galaxy collection build    # produces lvw5264-vsftpd-2.0.0.tar.gz
ansible-galaxy collection install lvw5264-vsftpd-2.0.0.tar.gz
```

### Reference the role in an ansible playbook

```yaml
- hosts: all
  collections:
    - lvw5264.vsftpd
  roles:
    - vsftpd
```

Or via FQCN:

```yaml
- hosts: all
  tasks:
    - name: Include vsftpd role
      ansible.builtin.include_role:
        name: lvw5264.vsftpd.vsftpd
```

### Override variables

In Ansible, any variable (group/host vars, playbook `vars:`, `--extra-vars`) shadows defaults. For example to enable a certificate on a certain node `vsftpd.yourdomain.com`:

```yaml
# host_vars/vsftpd.yourdomain.com.yml
vsftpd_ensure: absent
vsftpd_ssl_enable: true
vsftpd_rsa_cert_file: /etc/pki/tls/certs/vsftpd.yourdomain.com.pem
vsftpd_rsa_private_key_file: /etc/pki/tls/private/vsftpd.yourdomain.com.key
```

Compare to Puppet hieradata in a controlrepo:

```yaml
vsftpd::ensure: absent
vsftpd::ssl_enable: true
vsftpd::rsa_cert_file: /etc/pki/tls/certs/vsftpd.yourdomain.com.pem
vsftpd::rsa_private_key_file: /etc/pki/tls/private/vsftpd.yourdomain.com.key
```
