base:
  '*':
    - default 
    - snmp
    - monitor
    - saltmine
    - nrpe
  'nagios*':
    - snmp
    - apache
    - nagios
    - nrpe
