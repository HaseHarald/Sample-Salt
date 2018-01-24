# smartmontools - SMART Disk Monitoring

{% set state_version = '0.0.2' %}
{% if pillar['smartmontools'] is defined %}
{%   set pillar_version = pillar['smartmontools'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'raspbian' %}
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

{% if pillar['smartmontools'] is defined %}
{%   set hdd_list = pillar['smartmontools'].get('device_list', []) %}
{% else %}
{%   set hdd_list = grains['disks'] %}

notification-smartmontools:
  test.show_notification:
    - text: {{ 'You can define optional pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% for device in hdd_list if not device == "sr0" %} # This is not the prefered solution for filtering out optical drives.
smart-activate-{{ device }}:
  cmd.run:
    - name: smartctl -s on /dev/{{ device }}
    - onlyif: "smartctl -i /dev/{{ device }} | grep -q 'SMART support is: Disabled'"
    - user: root
    - require:
      - pkg: pkg-smartmontools
{% endfor %}

/etc/default/smartmontools:
  file.managed:
    - source: salt://{{ os_path }}/SMART/etc/default/smartmontools
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: pkg-smartmontools

/etc/smartd.conf:
  file.managed:
    - source: salt://{{ os_path }}/SMART/etc/smartd.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      hdd_list: {{ hdd_list }}
    - require:
      - pkg: pkg-smartmontools

{% include os_path ~ "/etckeeper/commit.sls" %}


# Pillar Example
# --------------
# smartmontools:
#   pillar_version: '0.0.1'
#   device_list:
#     - sda
#     - sdb
#     - sdc
