# vnStat - Network statistics

{% set state_version = '0.0.2' %}
{% if pillar['vnstat'] is defined %}
{%   set pillar_version = pillar['vnstat'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/vnstat.conf'
] %}

pkg-vnstat:
  pkg.installed:
    - name: vnstat

service-vnstat:
  service.running:
    - name: vnstat
    - enable: True
    - watch:
      - file: /etc/vnstat.conf
    - require:
      - pkg: pkg-vnstat

{% if pillar['vnstat'] is defined %}
{% for interface in pillar['vnstat'].get('interfaces', []) %}
cmd-vnstat-init-{{ interface.name }}:
  cmd.run:
    - user: root
    - name: vnstat --create -i {{ interface.name }}; vnstat -u -i {{ interface.name }}
    - unless: test -f /var/lib/vnstat/{{ interface.name }}
    - require:
      - pkg: pkg-vnstat
{% endfor %}

{% if pillar['vnstat']['default-interface'] is defined %}
/etc/vnstat.conf:
  file.managed:
    - name: /etc/vnstat.conf
    - source: salt://mint_18-2/vnstat/etc/vnstat.conf.jinja
    - template: jinja
    - require:
      - pkg: pkg-vnstat
{% endif %}

{% else %}

notification-vnstat:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

cmd-vnstat-permissions:
  file.directory:
    - name: /var/lib/vnstat
    - makedirs: False
    - user: vnstat
    - group: vnstat
    - recurse:
      - user
      - group
    - require:
      - pkg: pkg-vnstat

{% include "mint_18-2/etckeeper/commit.sls" %}


# Pillar Example
# --------------
# vnstat:
#   pillar_version: '0.0.1'
#   interfaces:
#     - enp0s3:
#       name: enp0s3
#     - enp0s8:
#       name: enp0s8
#       maxBW: 100
#   max-bandwidth: 1000
#   default-interface: enp0s3
