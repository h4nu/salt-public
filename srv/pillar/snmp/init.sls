snmpd:
  lookup:
    config:
      tmpl: salt://snmpd/files/snmpd.conf
snmp_syslocation: 'Borough/Helsinki/Finland'
snmp_syscontact: 'John Doe <john@doe.org>'
snmp_rocommunity: your-ro-community
snmp_management_station: 192.168.13.52
snmp_allowed_networks: 192.168.13.0/24
snmp_rouser: your-ro-user
snmp_rouser_pass: 'ro-user password'
snmp_rouser_seclevel: authNoPriv
snmp_rwuser: your-rw-user
snmp_rwuser_pass: 'rw-user password'
snmp_rwuser_enc: your-rw-user-enc
snmp_rwuser_seclevel: authPriv
