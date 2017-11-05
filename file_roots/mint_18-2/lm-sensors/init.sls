# lm-sensors - Programm to read sensor-data

{% set state_version = '0.0.1' %}
{% if pillar['sensors'] is defined %}
{%   set pillar_version = pillar['sensors'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'cmd: cmd-sensors-detect'
] %}

pkg-lm-sensors:
  pkg.installed:
    - name: 'lm-sensors'
    
cmd-sensors-detect:
  cmd.run:
    - user: root
    - name: sensors-detect --auto
    - unless: grep -q sensors-detect /etc/modules
    - require:
      - pkg: pkg-lm-sensors

service-kmod:
  service.running:
    - name: kmod
    - enable: True
    - watch:
      - cmd: cmd-sensors-detect
    - require:
      - pkg: pkg-lm-sensors
      
{% include "mint_18-2/etckeeper/commit.sls" %}
