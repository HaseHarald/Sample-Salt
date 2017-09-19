# turns of IPv6 support in the kernel

{% set state_version = '0.0.1' %}
{% if pillar['noIPv6'] is defined %}
{%   set pillar_version = pillar['noIPv6'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/sysctl.d/noipv6.conf'
] %}

/etc/sysctl.d/noipv6.conf:
  file.managed:
    - name: /etc/sysctl.d/noipv6.conf
    - source: salt://debian/network/etc/sysctl.d/noipv6.conf.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      ifaces: {{ grains['ip_interfaces'].keys() }}

cmd-noipv6-load-sysctl-settings:
  cmd.run:
    - name: '/sbin/sysctl -p /etc/sysctl.d/noipv6.conf'
    - user: root
    - require: 
      - file: /etc/sysctl.d/noipv6.conf
    - onchanges:
      - file: /etc/sysctl.d/noipv6.conf

{% include "debian/etckeeper/commit.sls" %}
