# install the files required for compile
prepkgs:
  pkg.installed:
    - pkgs:
      - autoconf
      - bc
      - gawk
      - dc
      - build-essential
      - gcc
      - libc6
      - make
      - wget
      - unzip
      - php
      - libapache2-mod-php7.2
      - libgd-dev
      - libmcrypt-dev
      - libssl-dev
      - libnet-snmp-perl
      - gettext 
 

install-foo:
  cmd.run:
    - name: |
        cd /usr/local/src
        wget https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.6.tar.gz
        tar xzf nagios-4.4.6.tar.gz
        cd nagioscore-nagios-4.4.6/
        ./configure --with-httpd-conf=/etc/apache2/sites-enabled
        make all
        make install-groups-users
        usermod -a -G nagios www-data
        make install
        make install-daemoninit
        make install-init
        make install-commandmode
        make install-config
        make install-webconf
        a2enmod rewrite cgi
        mkdir -p /usr/local/nagios/etc/servers

    - cwd: /tmp
    - shell: /bin/bash
    - timeout: 300
    - unless: test -x /usr/local/nagios/bin/nagios

/usr/local/nagios/etc/htpasswd.users:
  file.managed:
    - source: salt://nagios/files/htpasswd.users
    - user: root
    - group: root
    - mode: 644

nagios plugins:
  pkg.installed:
    - pkgs:
      - nagios-plugins
      - nagios-nrpe-plugin

/usr/local/nagios/etc/nagios.cfg:
  file.managed:
    - source: salt://nagios/files/nagios.cfg
    - user: nagios
    - group: nagios
    - mode: 0664

/usr/local/nagios/etc/resource.cfg:
  file.managed:
    - source: salt://nagios/files/resource.cfg
    - user: nagios
    - group: nagios
    - mode: 0660

/usr/local/nagios/etc/objects/contacts.cfg:
  file.managed:
    - source: salt://nagios/files/contacts.cfg
    - user: nagios
    - group: nagios
    - mode: 0664

/usr/local/nagios/etc/objects/commands.cfg:
  file.managed:
    - source: salt://nagios/files/commands.cfg
    - user: nagios
    - group: nagios
    - mode: 0664

nagios service:
  service.running:
    - name: nagios
    - enable: True
    - restart: True
    - watch:
      - file: /usr/local/nagios/etc/*

post-tasks:
 cmd.run:
   - name: |
       cd /tmp
       systemctl restart apache2
#       systemctl start nagios
#       systemctl enable nagios
#    - cwd: /tmp
#    - shell: /bin/bash
#    - timeout: 300
#    - unless: test -x /usr/local/nagios/bin/nagios
