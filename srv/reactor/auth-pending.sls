{# test server is sending new key -- accept this key #}
   {% if 'act' in data and data['act'] == 'pend' and data['id'].startswith('test') %}
minion_add:
  wheel.key.accept:
    - match: {{ data['id'] }}
{% endif %}
