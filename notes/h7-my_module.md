# Configuration Management Systems - ict4tn022-3010

Exercises in the course:  
[h1 hello master-slave](h1-hello-master-slave.md)  
[h2 package file-server](h2_package_file-server.md)  
[h3 version control](h3-versionhallinta.md)  
[h4 timeline](h4-timeline.md)  
[h5 new command](h5-new-command.md)  
[h6 moottorix](h6-moottorix.md)  
[h7 own module part 1](h7-my_module.md)  
[h7 own module part 2](h7-nagios.md)  

## own module - part 1: Automate VMware virtual server deployment with Salt

My original idea was to test some monitoring system and deploy those with Salt.
As there was risk of some probes or network scanning I thought to create a separate test network...

I had already a VMware lab cluster at home but I was missing a separate test network. I had used my guest network earlier for testing purposes.  

I created necessary vlans to switches and my VMware cluster and configured my high available pfSense firewall cluster to provide private IPv4 addresses and real IPv6 addresses (/64) for the test network to completely isolate the test servers.

My dhcp server is integrated to my DNS system so I created also corresponding reverse zones (both IPv4 and IPv6) to make things easier...

But then I thought that it would be nice to spawn up multiple virtual servers rapidly whenever I need new test servers...

So I decided to automate my deployments with Salt too.

This approach relies on salt-cloud:  
`https://docs.saltstack.com/en/master/topics/cloud/vmware.html`

As we have installed and configured the Salt already, we'll install salt-cloud package:  

`sudo apt install salt-cloud`

The VMware cloud module relies on pyVmoni package.

While the python on the system was defaulting python2.7 and Salt is using python3.
I installed the dependent package pyVmomi with the **`pip3 install`** command instead of just `pip install` :  

`pip3 install pyVmomi`


## Prepare the template

I didn't have any templates earlier, so I installed a clean Ubuntu Server 18.04.

It was time to do some finalization activities


First we need to create a ssh-key that Salt is using for bootstrapping Salt after the virtual machine has been cloned from the template. 

This is done in the salt server:

Salt server:

`sudo ssh-keygen -f /etc/salt/campus_salt_cloud_key -t rsa -b 4096`

`sudo chown salt /etc/salt/campus_salt_cloud_key`

On the template virtual server we'll need to add saltuser, copy the public key to it and do some cleanups and preparations for the cloning process. 

template virtual server:

```
# Add saltuser
adduser saltuser

# Install SSH key
mkdir -p /home/saltuser/.ssh
echo "<contents of the campus_salt_cloud_key.pub public -ssh key>" >> /home/saltuser/.ssh/authorized_keys
chmod 700 /home/saltuser/.ssh
chmod 600 /home/saltuser/.ssh/authorized_keys
chown -R saltuser:saltuser /home/saltuser/.ssh

# Set password for the saltuser user
echo -n 'saltuser:<password hash>' | chpasswd -c SHA512

# Enable sudo for the saltuser
echo "saltuser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/saltuser

```

Cleanup the VM template.
I ended up creating a script combining these sources: 
https://kb.vmware.com/s/article/54986
https://infiniteloop.io/vmware-template-ubuntu-18-04-3-lts/
https://jimangel.io/post/create-a-vm-template-ubuntu-18.04/
https://everythingshouldbevirtual.com/virtualization/Ubuntu-18.04-Templates-Duplicate-IPs/

vm.cleanup.sh:

```
#!/bin/sh
# Remove the cloud-init
sudo cloud-init clean --logs
sudo touch /etc/cloud/cloud-init.disabled
sudo rm -rf /etc/netplan/50-cloud-init.yaml
sudo apt purge cloud-init -y
sudo apt autoremove -y

echo Update system
apt update -y && apt upgrade -y

echo Stop rsyslog
service rsyslog stop
echo Empty log files
find /var/log/ -type f -exec cp /dev/null {} \;
echo Remove tmp files
rm -rf /tmp/*
rm -rf /var/tmp/*


# cleanup apt
sudo apt clean

# Cleanup host ssh keys 
sudo rm -f /etc/ssh/ssh_host_*

# Check for ssh keys on reboot and regenerate if neccessary
echo Create /etc/rc.local to regenerate ssh host keys if needed
sudo cat << 'EOL' > /etc/rc.local 
#!/bin/sh
if [ ! -e /etc/ssh/ssh_host_rsa_key ]; then
  dpkg-reconfigure openssh-server
  systemctl restart ssh
fi
exit 0
EOL

# make the script executable
sudo chmod +x /etc/rc.local

# VMware customization fix https://kb.vmware.com/s/article/56409
if grep -E '^#D \/tmp 1777 root root' /usr/lib/tmpfiles.d/tmp.conf
then
  echo VM tools tmp.conf customizations already exists 
else
  echo Adding VM tools tmp.conf customization
  sed -i 's/^D \/tmp 1777 root root -/#D \/tmp 1777 root root -/' /usr/lib/tmpfiles.d/tmp.conf
fi
if grep -E '^After=dbus.service' /lib/systemd/system/open-vm-tools.service
then
  echo VM tools service customization already exists 
else
  echo Adding VM tools service customization
  sed -i '/^\[Unit\]/a\After=dbus.service' /lib/systemd/system/open-vm-tools.service
fi

echo Remove unwanted MOTD detail
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news

# Fix machine-id issue with duplicate IP addresses being assigned
if [ -f /etc/machine-id ]; then
    sudo truncate -s 0 /etc/machine-id
fi

#reset hostname
truncate -s0 /etc/hostname
hostnamectl set-hostname localhost


# echo Clear bash history
cp /dev/null ~/.bash_history && history -cw
```

Now, when the template is ready, we can create necessary salt-cloud configurations for the vmware:
We need to create a provider and a profile files.

First we'll need to create a provider which in this case is our vCenter server:  

`sudoedit /etc/salt/cloud.providers.d/vmware.conf`

```
# vCenter configuration:
vc01:
  driver: vmware
  user: 'admin-account-here'
  password: 'password-here'
  url: 'virtual-center-address-here'
```

The "vc01:" will be used by the profiles to map the templates to the provider (vc01).

Next we'll create the profile, which will be called upon requesting new virtual servers:  

sudoedit /etc/salt/cloud.profiles.d/vmware.conf

```
#
base-ubuntu-1804lts:
  # provider below maps to vc01 in /etc/salt/cloud.providers.d/vmware.conf created earlier step
  provider: vc01
  deploy: True
  customization: True
  # This one is in the iSCSI backed shared storage
  clonefrom: "your-template-or-virtual-server"
  datacenter: data-center-name-here
  cluster: cluster-name-here

  ## Optional arguments
  num_cpus: 1
  memory: 1GB

  devices:
    network:
      'Network adapter 1':
        name: 'vss_yournetwork-here'
        # switch_type can be either 'standard' or 'distributed'
        switch_type: standard
        adapter_type: vmxnet3
        # we won't configure ip-addresses or domain as we'll rely on dhcp

  domain: your-domain-name-here

  # To ssh into the machine for Salt bootstrapping
  ssh_username: your-local-salt-user-here
  password: "your-salt-user-password-here"
  private_key: /etc/salt/your_salt_cloud_key

  datastore: your-datastore-here

  # Minion configuration
  minion:
    master: salt-master-ip-address

    # Report IP addresses back to the Salt Mine
    mine_functions:
      network.ip_addrs: []

    # Force a mine.update when the minion comes alive.
    startup_states: sls
    sls_list:
      - mine.update_mine

ubuntu-esx01:
  # provider below maps to vc01 in /etc/salt/cloud.providers.d/vmware.conf created earlier step
  provider: vc01
  deploy: True
  # This is in local SSD drive
  clonefrom: "your-template-or-virtual-server"
  customization: True
  num_cpus: 1
  memory: 1GB

  host: your-esxi-target-host-here-if-you-want-to-target-specific-esxi-host

  devices:
    network:
      'Network adapter 1':
        name: 'vss_your-network-here'
        switch_type: standard
        adapter_type: vmxnet3
        # we won't configure ip-addresses as we'll rely on dhcp

  domain: your-domain-name-here

  ssh_username: your-local-salt-user-here
  password: "your-saltuser-password-here"
  private_key: /etc/salt/your_salt_cloud_key
  datastore: your-datastore-here

  minion:
    master: salt-master-ip-address

    mine_functions:
      network.ip_addrs: []

    startup_states: sls
    sls_list:
      - mine.update_mine

# Test server
test-ubuntu:
  # provider below maps to vc01 in /etc/salt/cloud.providers.d/vmware.conf created earlier step
  provider: vc01
  deploy: True
  clonefrom: "your-template-or-virtual-server"
  customization: True
  num_cpus: 1
  memory: 1GB

  host: your-esxi-target-host-here-if-you-want-to-target-specific-esxi-host

  devices:
    network:
      'Network adapter 1':
        # Test network
        name: 'vss_your-network-here'
        switch_type: standard
        adapter_type: vmxnet3
  ssh_username: your-local-salt-user-here
  password: "your-salt-user-password-here"
  private_key: /etc/salt/your_salt_cloud_key
  datastore: your-datastore-here

  minion:
    master: salt-master-ip-address
    

    mine_functions:
      network.ip_addrs: []

    startup_states: sls
    sls_list:
      - mine.update_mine

# Test server which register with Salt test server
testsalt-ubuntu:
  # provider below maps to vc01 in /etc/salt/cloud.providers.d/vmware.conf created earlier step
  provider: vc01
  deploy: True
  clonefrom: "your-template-or-virtual-server"
  customization: True
  num_cpus: 1
  memory: 1GB

  host: your-domain-here

  devices:
    network:
      'Network adapter 1':
        # Test network
        name: 'vss_your-network-here'
        switch_type: standard
        adapter_type: vmxnet3
  ssh_username: your-saltuser
  password: "your-salt-user-password-here"
  private_key: /etc/salt/your_salt_cloud_key
  datastore: your-datastore-here

  minion:
    # Salt test server
    master: test-salt-master-ip-address

    mine_functions:
      network.ip_addrs: []

    startup_states: sls
    sls_list:

```
I ended up having four profiles.
1. First profile uses iSCSI backed shared storage and registers with "prod" Salt server. 
2. Second profile uses ssd storage and registers with "prod" Salt server.
3. Third one is for test servers with test network and ssd storage registering with "prod" Salt server
4. Fourth profile creates a virtual machine to test network and register with our "test" Salt server instead of the "prod" Salt server triggering the provisioning job.

The automatic registration of the test servers to test salt server is not yet implemented and the keys must be accepted by the master manually.

Let's test the first virtual machine:

`salt-cloud -p test-ubuntu-esx01 testnode1`

```
    guest_id:
        ubuntu64Guest
    hostname:
        testnode1
    id:
        testnode1
    image:
        Ubuntu Linux (64-bit) (Detected)
    mac_addresses:
        - 00:50:56:a9:b2:d5
    networks:
        ----------
        vss_Campus_VLAN100:
            ----------
            connected:
                True
            ip_addresses:
                - 192.168.13.91
                - 2001:14ba:1ffe:CENSORED
                - 2001:14ba:1ffe:CENSORED
                - fe80::250:56ff:fea9:b2d5
            mac_address:
                00:50:56:a9:b2:d5
    path:
        [esx01_datastore_01] node1/node1.vmx
    private_ips:
        - 192.168.13.91
        - 2001:14ba:1ffe:CENSORED
        - 2001:14ba:1ffe:CENSORED
        - fe80::250:56ff:fea9:b2d5
    public_ips:
    size:
        cpu: 1
        ram: 1024 MB
    state:
        poweredOn
    storage:
        ----------
        committed:
            4501545452
        uncommitted:
            13835960870
        unshared:
            3343908864
    tools_status:
        toolsOk

real	2m27.168s
user	0m8.476s
sys	0m0.761s
```

The deployment of a new virtual server was fast enough :)

You could create multiple virtual machines at once by using -P (parallel switch 
i.e. salt-cloud -p profile-name first-virtual-server second-virtual-server third-virtual-server

We can get the status of the virtual servers (nodes) with command:

`salt-cloud -f list_nodes_min vc01`

```
        testnode1:
            ----------
            id:
                testnode1
            state:
                Running

```

We can check that the virtual server has been registered with salt:

salt-key --list all

Accepted Keys:
node1

We can shutdown the provisioned virtual seerver with command:  
`sudo salt-cloud  -a stop virtual-server-name`


We can destroy the provisioned virtual server with command: 
`salt-cloud -d virtual-server-name`

You can destroy multiple virtual servers at once by specifying their names separated by space.

Accpting keys automatically.

While the salt-cloud handles the acceptance of the minions automatically, the virtual servers provisioned to the test salt master server requires manual acceptance. 

I tested on the test salt master server accepting the minions automatically based on their names.
This approach is not recommended but my test network is isolated from the rest of my home infrastructure so I decided to test it.

I created a new file /etc/salt/master.d/reactor.conf:

`sudoedit /etc/salt/master.d/reactor.conf`

```
reactor:
  - 'salt/auth':
    - /srv/reactor/auth-pending.sls
```

And the directory for reactor state files.  

`sudo mkdir /srv/reactor/`

As well as the state file for accepting the keys:   

`sudoedit /srv/reactor/auth-pending.sls`

```
{# test server is sending new key -- accept this key #}
   {% if 'act' in data and data['act'] == 'pend' and data['id'].startswith('test') %}
minion_add:
  wheel.key.accept:
    - match: {{ data['id'] }}
{% endif %}
```



Now when we have implemented the small virtual server automation, we can proceed further with rest of the use cases in this module.

[Part 2](https://hanu.org/ict4tn022-3010/h7-nagios.html)  


References used:  

https://kb.vmware.com/s/article/59687  
https://github.com/saltstack/salt/issues/52196  
https://infiniteloop.io/vmware-template-ubuntu-18-04-3-lts/  
https://blog.ikigo.net/?p=344  
