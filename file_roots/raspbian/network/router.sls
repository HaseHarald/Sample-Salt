# enable ipv4 forwarding

{% set state_version = '0.0.2' %}
{% if pillar['router'] is defined %}
{%   set pillar_version = pillar['router'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/sysctl.d/ipv4forward.conf'
] %}

include:
  - raspbian.network.firewalling-pkgs

/etc/sysctl.d/ipv4forward.conf:
  file.managed:
    - name: /etc/sysctl.d/ipv4forward.conf
    - source: salt://raspbian/network/etc/sysctl.d/ipv4forwarding.conf
    - user: root
    - group: root
    - mode: 644

enable-ipv4-forward:
  cmd.run:
    - name: 'echo 1 > /proc/sys/net/ipv4/ip_forward'
    - unless: '/bin/grep 1 /proc/sys/net/ipv4/ip_forward'

{% if pillar['router'] is defined %}
{%   if pillar['router']['nat'] %}
{%     for iface in pillar['router']['nat-interfaces'] %}
nat-on-{{ iface }}:
  iptables.append:
    - table: nat
    - chain: POSTROUTING
    - jump: MASQUERADE
    - o: {{ iface }}
    - save: True
{%     endfor %}
{%   endif %}
{% else %}

notification-ip-route:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% include "raspbian/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# router:
#   pillar_version: '0.0.1'
#   nat: True
#   nat-interfaces:
#     - enp0s3
