base:
# For all targets
  '*':
    - basetools
    - nagios.client
    - default
  'testnagios*':
    - snmp
    - postfix
    - apache
    - nagios
