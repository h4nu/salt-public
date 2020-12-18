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

## h2 Package-File-Service

### Exercise a) Daemon settings. 

Configure a daemon (install + configure + test) with a package-file-service structure.

An extended apache and default settings configuration:

Install and test apache manually:

Slave:

`sudo apt install apache2 && sudo mkdir -p /var/www/html/campus.hanu.org`

`vi /var/www/html/campus.hanu.org/index.html`

```
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Campus web server</title>
</head>
<body>

<h1>Apache web server</h1>
<p>Server up and running.</p>

</body>
</html>
```


`vi /etc/apache2/conf-available/tune_apache.conf`

```
# prefork MPM
<IfModule mpm_prefork_module>
        StartServers 5
        MinSpareServers 5
        MaxSpareServers 10
        MaxRequestWorkers 150
        MaxConnectionsPerChild 10000
</IfModule>
```

Enable the tuning configuration:

```
sudo a2enconf tune_apache.conf

```

Create a new virtual host:
`vi /etc/apache2/sites-available/campus.hanu.org.conf`

```
<VirtualHost *:80>
ServerName ict4n022-slave.campus.hanu.org
ServerAlias www.campus.hanu.org
DocumentRoot /var/www/html/campus.hanu.org/
ErrorLog /var/log/apache2/campus.hanu.org-error.log
CustomLog /var/log/apache2/campus.hanu.org-access.log combined
</VirtualHost>
```
Enable the new virtual host:
`sudo a2ensite campus.hanu.org`

Reload the apache with the new configuration and the virtual host (site):

`systemctl reload apache2`

Remove manually installed apache2 as well as the configuration and index.html files from the minion:

`sudo dpkg --purge apache2 &&  sudo rm -rf /etc/apache2/ && sudo rm -rf /var/www/html/`


Steps for configuring the same settings with Salt:

Master:

Step 1 

Create a [pillar](https://docs.saltstack.com/en/getstarted/config/pillar.html) directory, where we are going to define secure data that are ‘assigned’ to one or more minions using targets. Salt pillar data stores values such as ports, file paths, configuration parameters, and passwords. We are using pillars within this exercise to store web server domain configuration and some default configurations.

	sudo mkdir -p /srv/pillar/{apache,default}


```
/srv/pillar/
├── apache
└── default
```

Step 2

Create a Pillar top file referring to a default for all minions and apache for a specific host

`vi /srv/pillar/top.sls`

```
base:
  '*':
    - default
  ict4n022-slave:
    - apache
```

Step 3

Edit the default and apache settings. 

This time we are only defining an editor parameter as a default parameter for the minions.
`vi /srv/pillar/default/init.sls`

```
# define editor
editor: vim
```
Define the domain parameter for the apache settings. 

vi /srv/pillar/apache/init.sls


```
# Set the domain for the apache
domain: campus.hanu.org
```

Step 4

Refresh salt pillar values

`salt '*' saltutil.refresh_pillar`


Step 5

Create the directory:

`mkdir /srv/salt/campus.hanu.org`

and a mimimal index.html file for the website:
`vi /srv/salt/campus.hanu.org/index.html`

```
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Campus web server</title>
</head>
<body>

<h1>Apache web server</h1>
<p>Server up and running.</p>

</body>
</html>
```


Step 6 

Create apache configuration files

Apache tuning files

`mkdir /srv/salt/files`

`vi /srv/salt/files/tune_apache.conf`

```
# prefork MPM
<IfModule mpm_prefork_module>
        StartServers 5
        MinSpareServers 5
        MaxSpareServers 10
        MaxRequestWorkers 150
        MaxConnectionsPerChild 10000
</IfModule>
```
Step 7

Create apache state file

`mkdir /srv/salt/apache`

The documentation of each sections in the apache state file is documented within the file itself:

`vi /srv/salt/apache/init.sls`

```
# Get hostname for the web server
{% set serverHostname = salt['grains.get']('host') %}

# deploy the apache2 package
apache2:
  pkg.installed

# set the daemon startup parameters
apache2 Service:
  service.running:
    - name: apache2
    - enable: True
    - require:
      - pkg: apache2

# Turn Off KeepAlive
Turn Off KeepAlive:
  file.replace:
    - name: /etc/apache2/apache2.conf
    - pattern: 'KeepAlive On'
    - repl: 'KeepAlive Off'
    - show_changes: True
    - require:
      - pkg: apache2

# create referred files in /srv/salt/files/
/etc/apache2/conf-available/tune_apache.conf:
  file.managed:
    - source: salt://files/tune_apache.conf
    - require:
      - pkg: apache2

# Enable the tuning with the file created earlier
Enable tune_apache:
  apache_conf.enabled:
    - name: tune_apache
    - require:
      - pkg: apache2

# create the file structure for the html pages
/var/www/html/{{ pillar['domain'] }}:
  file.directory

/var/www/html/{{ pillar['domain'] }}/log:
  file.directory

/var/www/html/{{ pillar['domain'] }}/backups:
  file.directory

# Disable the default virtual host configuration file 
000-default:
  apache_site.disabled:
    - require:
      - pkg: apache2

# define the virtual host configuration file
/etc/apache2/sites-available/{{ pillar['domain'] }}.conf:
  apache.configfile:
    - config:
      - VirtualHost:
          this: '*:80'
          # define the ServerName from the serverHostname variable defined in the row 2 and from the pillar variable domain
          ServerName:
            - {{ serverHostname }}.{{ pillar['domain'] }}
          # define the ServerAlias combining the domain variable from the pillar
          ServerAlias:
            - www.{{ pillar['domain'] }}
          DocumentRoot: /var/www/html/{{ pillar['domain'] }}/
          #Error logs into standard logging directory (/var/log/apache/site-domain)
          ErrorLog: /var/log/apache2/{{ pillar['domain'] }}-error.log
          #Custom logs into standard logging directory (/var/log/apache/site-domain) 
          CustomLog: /var/log/apache2/{{ pillar['domain'] }}-access.log combined

# enable the virtual host configuration file
{{ pillar['domain'] }}:
  apache_site.enabled:
    - require:
      - pkg: apache2

# transfer the index.html file (/srv/salt/DOMAIN/index.html) into the web server (minion)
/var/www/html/{{ pillar['domain'] }}/index.html:
  file.managed:
    - source: salt://{{ pillar['domain'] }}/index.html
```
Deploy the configuration and install apache:

`sudo salt '*' state.apply apache`

```
Succeeded: 12 (changed=11)
Failed:     0
-------------
Total states run:     12
Total run time:   26.273 s
```
Test the website with httpie:

`http http://slave.campus.hanu.org`

```
HTTP/1.1 200 OK
Accept-Ranges: bytes
Connection: close
Content-Encoding: gzip
Content-Length: 160
Content-Type: text/html
Date: Thu, 12 Nov 2020 08:10:45 GMT
ETag: "be-5b3db2afbf228-gzip"
Last-Modified: Wed, 11 Nov 2020 21:06:23 GMT
Server: Apache/2.4.29 (Ubuntu)
Vary: Accept-Encoding

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Campus web server</title>
</head>
<body>

<h1>Apache web server</h1>
<p>Server up and running.</p>

</body>
</html>
```

### Exercise b) 
Install a new software. 

Slave:

Install a fail2ban software:

`sudo apt install fail2ban`

Remove the fail2ban package:
`sudo dpkg --purge fail2ban`

Master:
```
sudo mkdir -p /srv/salt/fail2ban
vi /srv/salt/fail2ban/init.sls
```

```
fail2ban:
  pkg.installed
```

`sudo salt '*' state.apply fail2ban`

```
ict4n022-slave:
----------
          ID: fail2ban
    Function: pkg.installed
      Result: True
     Comment: The following packages were installed/updated: fail2ban
     Started: 23:13:52.707739
    Duration: 25280.57 ms
     Changes:   
              ----------
              fail2ban:
                  ----------
                  new:
                      0.10.2-2
                  old:

Summary for ict4n022-slave
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time:  25.281 s
```

Slave:
Check the changes in the minion:
`sudo find /etc/ -printf '%T+ %p\n'|sort`

```
2020-11-11+23:08:13.7181735740 /etc/python2.7
2020-11-11+23:08:19.5542033170 /etc/mailcap
2020-11-11+23:08:23.0102209170 /etc/python
2020-11-11+23:08:23.0182209580 /etc/python/debian_config
2020-11-11+23:11:26.9991449510 /etc/systemd/system
2020-11-11+23:14:07.0519321960 /etc/
2020-11-11+23:14:07.0519321960 /etc/monit
2020-11-11+23:14:07.2719332700 /etc/bash_completion.d
2020-11-11+23:14:07.2799333090 /etc/default
2020-11-11+23:14:07.8719361980 /etc/fail2ban/action.d
2020-11-11+23:14:08.2319379550 /etc/fail2ban/filter.d/ignorecommands
2020-11-11+23:14:08.6719401020 /etc/fail2ban/filter.d
2020-11-11+23:14:08.6919402000 /etc/fail2ban/jail.d
2020-11-11+23:14:08.7279403750 /etc/fail2ban
2020-11-11+23:14:08.7359404140 /etc/init.d
2020-11-11+23:14:08.7439404530 /etc/logrotate.d
2020-11-11+23:14:08.7559405120 /etc/monit/monitrc.d
2020-11-11+23:14:09.6519448840 /etc/systemd/system/multi-user.target.wants
2020-11-11+23:14:09.6519448840 /etc/systemd/system/multi-user.target.wants/fail2ban.service
2020-11-11+23:14:10.3759484160 /etc/rc0.d
2020-11-11+23:14:10.3759484160 /etc/rc0.d/K01fail2ban
2020-11-11+23:14:10.3759484160 /etc/rc1.d
2020-11-11+23:14:10.3759484160 /etc/rc1.d/K01fail2ban
2020-11-11+23:14:10.3759484160 /etc/rc2.d
2020-11-11+23:14:10.3759484160 /etc/rc2.d/S01fail2ban
2020-11-11+23:14:10.3759484160 /etc/rc3.d
2020-11-11+23:14:10.3759484160 /etc/rc3.d/S01fail2ban
2020-11-11+23:14:10.3759484160 /etc/rc4.d
2020-11-11+23:14:10.3759484160 /etc/rc4.d/S01fail2ban
2020-11-11+23:14:10.3759484160 /etc/rc5.d
2020-11-11+23:14:10.3759484160 /etc/rc5.d/S01fail2ban
2020-11-11+23:14:10.3759484160 /etc/rc6.d
2020-11-11+23:14:10.3759484160 /etc/rc6.d/K01fail2ban
```


### Exercise c) 
Run some state locally without master-slave architecture.

`tree  /srv/salt/hello/`

```
/srv/salt/hello/
├── hellosalt.txt
└── init.sls
```

`cat /srv/salt/hello/init.sls `

```
/tmp/hellosalt.txt:
  file.managed:
    - source: salt://hello/hellosalt.txt
```

`cat /srv/salt/hello/hellosalt.txt`

```
Hei maailma
Toinen rivi
Kolmas rivi
```

`sudo salt-call --local state.apply hello -l debug`

```
local:
----------
          ID: /tmp/hellosalt.txt
    Function: file.managed
      Result: True
     Comment: File /tmp/hellosalt.txt updated
     Started: 23:24:03.232585
    Duration: 25.346 ms
     Changes:   
              ----------
              diff:
                  New file
              mode:
                  0644

Summary for local
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time:  25.346 ms
```

