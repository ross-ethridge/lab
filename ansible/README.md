# Ansible
## Configuration Files
- Default config file lives at 
```bash
/etc/ansible/ansible.cfg
```
- This is the first place it may consider for configuration options.
    - May also use use variables at: 
    ```bash
    /opt/<playbook-name>/ansible.cfg
    ```
- You man also use ```ENVIRONMENT_VARIABLES```:
```bash
export ANSIBLE_CONFIG='/path/to/some/other/ansible.cfg'

# The below command will now use the above config file by default.
ansible playbook playbook.yaml
```
- Use ```ansible-config list``` to see available configuration options.
- Use ```ansible-config view``` to see the current config settings.
- Use ```ansible-config dump``` to dump your current config to see what options are being used.

## Inventory
- https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html
- Use grouping to imply parent <==> child relationships.
- Defines logical groupings of servers in ```INI``` format.
```bash
mail ansible_host=server1.domain.com

[webservers]
web1 ansible_host=web1.other-co.com
web2 ansible_host=web2.other-co.uk

[webservers:children]
web1
web2

[dbservers]
db1.us.com
db2.eu.com
db3.replica.com

## Other inventory parameters
# ansible_port [ set to 22 by default for ssh ]
# ansible_connection
# ansible_user
# ansible_ssh_pass [ please don't ]
```

## Variables
- Variables can be added via a ```vars``` section in the playbook.yaml.
  - Use vars by calling them inside double brackets ```{{ var_name }}```
```bash
-
  name: Add dns server
  hosts: webservers
  vars:
    dns_server: "10.10.0.1"
    fqdn: 'hostname.us.com'
  tasks:
    - lineinfile:
      path: /etc/resolv.conf
      line: 'nameserver {{ dns_server }}'
```

- Variables can be passed in as a seperate file outside of the playbook.
```bash
# variables.yaml
dns_server: "10.10.0.1"
fqdn: 'hostname.us.com'
```

- Then pass in the ```--extra-vars``` argument:
```bash
ansible-playbook -i inventory.ini playbook.yml --extra-vars "@variables.yaml"
```