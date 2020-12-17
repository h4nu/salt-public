# Install mutt and postfix mutt packages.
#
# This formula supports setting an optional:
#
#  * 'aliases' file
#  * 'virtual' map file
#
# Both aliases and virtual use a pillar data schema
# which takes the following form:
#
# postfix:
#   aliases: |
#       postmaster: root
#       root: testuser
#       testuser: russell@example.com
#   virtual: |
#       example.com             this is a comment
#       test1@example.com       me@example.com
#       test2@example.com       me@example.com
#

# install mutt
mutt:
  pkg:
    - installed

# install postfix have service watch main.cf
postfix:
  pkg:
    - installed
  service:
    - running
    - enable: True
    - watch:
      - pkg: postfix
      - file: /etc/postfix/main.cf

# postfix main configuration file
/etc/postfix/main.cf:
  file.managed:
    - source: salt://postfix/main.cf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: postfix

# manage /etc/aliases if data found in pillar
{% if 'aliases' in pillar.get('postfix', '') %}
/etc/aliases:
  file.managed:
    - source: salt://postfix/aliases
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: postfix

run-newaliases:
  cmd.wait:
    - name: newaliases
    - cwd: /
    - watch:
      - file: /etc/aliases
{% endif %}

# manage /etc/aliases if data found in pillar
{% if 'aliases' in pillar.get('postfix', '') %}
/etc/aliases:
  file.managed:
    - source: salt://postfix/aliases
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: postfix

run-newaliases:
  cmd.wait:
    - name: newaliases
    - cwd: /
    - watch:
      - file: /etc/aliases
{% endif %}

# manage /etc/postfix/virtual if data found in pillar
{% if 'virtual' in pillar.get('postfix', '') %}
/etc/postfix/virtual:
  file.managed:
    - source: salt://postfix/virtual
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: postfix

run-postmap:
  cmd.wait:
    - name: /usr/sbin/postmap /etc/postfix/virtual
    - cwd: /
    - watch:
      - file: /etc/postfix/virtual
{% endif %}
