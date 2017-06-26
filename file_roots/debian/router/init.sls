# enable ipv4 forwarding

{% set state_version = '0.0.1' %}
{% if pillar['firewall'] is defined %}
{%   set pillar_version = pillar['firewall'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/sysctl.d/ipv4forward.conf'
] %}

/etc/sysctl.d/ipv4forward.conf:
  file.managed:
    - name: /etc/sysctl.d/ipv4forward.conf
    - source: salt://debian/router/etc/sysctl.d/ipv4forwarding.conf
    - user: root
    - group: root
    - mode: 644

enable-ipv4-forward:
  cmd.run:
    - name: 'echo 1 > /proc/sys/net/ipv4/ip_forward'
    - unless: '/bin/grep 1 /proc/sys/net/ipv4/ip_forward'

{% include "debian/etckeeper/commit.sls" %}
