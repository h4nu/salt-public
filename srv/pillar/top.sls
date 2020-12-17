base:
  '*':
    - default 
    - snmp
    - saltmine
    - nrpe
  'nagios*':
    - snmp
    - apache
    - nagios
    - nrpe
