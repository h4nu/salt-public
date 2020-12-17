nrpe:
  server:
    dont_blame_nrpe: 0
    command:
      check_users: '/usr/lib/nagios/plugins/check_users -w 5 -c 10'
      check_load: '/usr/lib/nagios/plugins/check_load -w 8,5,2 -c 10,8,3 -r'
      check_disk: '/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -e -l'
      check_procs: '/usr/lib/nagios/plugins/check_procs -w 250 -c 400'
      check_zombie_procs: '/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z'
      check_swap: '/usr/lib/nagios/plugins/check_swap -w 95% -c 20%'
      check_salt_master: '/usr/lib/nagios/plugins/check_procs -c 1: -C salt-master'
      check_salt_minion: '/usr/lib/nagios/plugins/check_procs -c 2 -C salt-minion'
      check_tftp_process: '/usr/lib/nagios/plugins/check_procs -c 1: -C in.tftpd'
      check_tftp: '/usr/local/lib/nagios/plugins/check_tftp.pl {{ grains['ipv4'][0] }} pxelinux.0'
      check_syslog-process: '/usr/lib/nagios/plugins/check_procs -c 1: -C syslog-ng'

      # apt-server checks
      check_apt-server: '/usr/lib/nagios/plugins/check_http -H {{ grains['ipv4'][0] }} -u /public_key.gpg --no-body -e "HTTP/1.1 200 OK"'

      # ossec-server checks
      check_ossec-maild: '/usr/lib/nagios/plugins/check_procs -c 0 -C ossec-maild'
      check_ossec-execd: '/usr/lib/nagios/plugins/check_procs -c 1: -C ossec-execd'
      check_ossec-analysisd: '/usr/lib/nagios/plugins/check_procs -c 1: -C ossec-analysisd'
      check_ossec-logcollector: '/usr/lib/nagios/plugins/check_procs -c 0 -C ossec-logcollector'
      check_ossec-syscheckd: '/usr/lib/nagios/plugins/check_procs -c 1: -C ossec-syscheckd'
      check_ossec-monitord: '/usr/lib/nagios/plugins/check_procs -c 1: -C ossec-monitord'
      check_ossec-authd: '/usr/lib/nagios/plugins/check_procs -c 0 -C ossec-authd'
      check_ossec-csyslogd: '/usr/lib/nagios/plugins/check_procs -c 1: -C ossec-csyslogd'

      # RabbitMQ
      check_rabbitmq-server: '/usr/lib/nagios/plugins/check_procs -c 1: -C rabbitmq-server'

      # Redis
      check_redis: '/usr/lib/nagios/plugins/check_procs -c 1: -C redis-server'
      check_sentinel: '/usr/lib/nagios/plugins/check_procs -c 1: -C redis-sentinel'
      
      # NFS server checks
      check_nfsd: '/usr/lib/nagios/plugins/check_procs -c 1: -C nfsd'
      check_nfsd4: '/usr/lib/nagios/plugins/check_procs -c 1: -C nfsd4'

      # nullmailer checks
      check_nullmailer: '/usr/lib/nagios/plugins/check_procs -c 1: -C nullmailer-send'
      check_nullmailer-queue: '/usr/local/lib/nagios/plugins/check_mailq -M nullmailer -w 10 -c 30'

# replace hosts/networks with your own networks
nrpe_allowed_hosts: 127.0.0.1,::1,192.168.13.0/24
