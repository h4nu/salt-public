include:
  - .install

{% for agent in salt['mine.get']('*', 'grains.items' ) -%}
  
/usr/local/nagios/etc/servers/{{ agent }}.cfg:
  file.managed:
    - source: salt://nagios/files/agent-nrpe.cfg
    - template: jinja
    - context:
      agent: {{ agent }}
#    - listen_in:
#      - service: nagios

{% endfor %}

restart nagios:
  service.running:
    - name: nagios
    - enable: True
    - restart: True
    - watch:
      - file: /usr/local/nagios/etc/servers/*
