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
/var/www/{{ pillar['domain'] }}:
  file.directory

/var/www/{{ pillar['domain'] }}/log:
  file.directory

/var/www/{{ pillar['domain'] }}/backups:
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
          DocumentRoot: /var/www/{{ pillar['domain'] }}/
          #Error logs into standard logging directory (/var/log/apache/site-domain)
          ErrorLog: /var/log/apache2/{{ pillar['domain'] }}-error.log
          #Custom logs into standard logging directory (/var/log/apache/site-domain) 
          CustomLog: /var/log/apache2/{{ pillar['domain'] }}-access.log combined

# enable the virtual host configuration file
{{ pillar['domain'] }}:
  apache_site.enabled:
    - require:
      - pkg: apache2

# distribute the certificates
/etc/ssl/le:
  file.recurse:
    - source: salt://apache/files/le
    - user: root
    - group: root
    - dir_mode: 0775
    - file_mode: 0644
    - include_empty: True

# define the ssl virtual host configuration file
/etc/apache2/sites-available/{{ pillar['domain'] }}-ssl.conf:
  file.managed:
    - source: salt://apache/files/ssl.conf
    - template: jinja

# Enable the mod_ssl module
mod_ssl:
  apache_module.enabled:
    - name: ssl
    - require:
      - pkg: apache2

# enable the ssl virtual host configuration file
{{ pillar['domain'] }}-ssl:
  apache_site.enabled:
    - require:
      - pkg: apache2

# transfer the index.html file (/srv/salt/DOMAIN/index.html) into the web server (minion)
/var/www/{{ pillar['domain'] }}/index.html:
  file.managed:
    - source: salt://{{ pillar['domain'] }}/index.html

# and restart the service:
restart service:
  service.running:
    - name: apache2
    - enable: True
    - restart: True
    - watch:
      - file: /etc/apache2/sites-available/*
