# include other components first
include:
  # Install snmp, postfix and apache first
  - snmp
  - postfix
  - apache
  # Then continue with the Nagios 
  - .install
  - .config-servers
