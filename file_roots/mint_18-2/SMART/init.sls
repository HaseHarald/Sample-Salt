# smartmontools - SMART Disk Monitoring

{% set state_version = '0.0.1' %}
{% if pillar['smartmontools'] is defined %}
{%   set pillar_version = pillar['smartmontools'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/default/smartmontools',
  'file: /etc/smartd.conf'
] %}

pkg-smartmontools:
  pkg.installed:
    - name: smartmontools

service-smartmontools:
  service.running:
    - name: smartd
    - enable: True
    - require:
      - pkg: pkg-smartmontools
    - watch:
      - file: /etc/default/smartmontools
      - file: /etc/smartd.conf
#      - file: /etc/smartmontools/*
# Documentation says this should work. Bugreports say it doesnt.
# https://github.com/saltstack/salt/issues/663

{% if pillar['smartmontools'] is defined %}
{% for device in pillar['smartmontools'].get('device_list', []) %}
smart-activate-{{ device }}:
  cmd.run:
    - name: smartctl -s on /dev/{{ device }}
    - onlyif: "smartctl -i /dev/{{ device }} | grep -q 'SMART support is: Disabled'"
    - user: root
    - require:
      - pkg: pkg-smartmontools
{% endfor %}

{% else %}

notification-smartmontools:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

/etc/default/smartmontools:
  file.managed:
    - source: salt://mint_18-2/SMART/etc/default/smartmontools
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: pkg-smartmontools

/etc/smartd.conf:
  file.managed:
    - source: salt://mint_18-2/SMART/etc/smartd.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: pkg-smartmontools

{% include "mint_18-2/etckeeper/commit.sls" %}


# Pillar Example
# --------------
# smartmontools:
#   pillar_version: '0.0.1'
#   device_list:
#     - sda
#     - sdb
#     - sdc
