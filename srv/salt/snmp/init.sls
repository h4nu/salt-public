# deploy the snmpd package
snmpd:
  pkg.installed

# set the daemon startup and reload parameters
snmpd Service:
  service.running:
    - name: snmpd
    - enable: True
    - reload: True
    - require:
      - pkg: snmpd
    - watch:
      - file: /etc/snmp/snmpd.conf

# distribute the snmpd.conf
/etc/snmp/snmpd.conf:
  file.managed:
    - source: salt://snmp/files/snmpd.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: snmpd
    - watch_in:
       - service: snmpd

# install the snmp tools to enable local clients
snmp:
  pkg.installed

# install the snmp-mibs-downloader package to download MIBs
snmp-mibs-downloader:
  pkg.installed

# comment out the mibs : line in snmp.conf to use the MIBs downloaded using the snmp-mibs-downloader 
snmp conf:
  file.replace:
    - name: /etc/snmp/snmp.conf
    - pattern: '^mibs :'
    - repl: '#mibs :'
    - show_changes: True
    - require:
      - pkg: snmp-mibs-downloader

# Update the MIBs to latest versions
download mibs:
  cmd.run:
    - name: download-mibs
    - watch:
      - file: /etc/snmp/snmp.conf
