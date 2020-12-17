# Get hostname of the minion
{% set serverHostname = salt['grains.get']('host') %}

refreshgrains:
  module.run:
    - name: saltutil.sync_grains

# Install required packages
  pkg.installed:
    - pkgs:
      - nagios-nrpe-server
      - nagios-plugins

/etc/nagios/nrpe.cfg:
  file.managed:
    - source: salt://nagios/files/nrpe.cfg
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

restart nrpe:
  service.running:
  - name: nagios-nrpe-server
  - enable: True
  - restart: True
  - watch:
    - file: /etc/nagios/nrpe.cfg

/etc/nagios/nrpe_local.cfg:
  file.managed:
    - source: salt://nagios/files/nrpe_local.cfg
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

/etc/nagios/{{ serverHostname }}-target.cfg:
  file.managed:
    - source: salt://nagios/files/target.cfg
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
