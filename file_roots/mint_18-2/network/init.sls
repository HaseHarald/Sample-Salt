# Network-Configuration
# This is probably not an ideal solution, but it works for now.
# TODO:
# - Changes are not activated without reboot
# - Have usage of vlan detected and install vlan-package automaticly

{% set state_version = '0.0.11' %}
{% if pillar['network'] is defined %}
{%   set pillar_version = pillar['network'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'mint_18-2' %}
{% set etckeeper_watchlist = [
  'file: /etc/network/interfaces',
  'file: /etc/network/if-up.d/routes-*',
  'file: /etc/network/if-down.d/routes-*',
  'file: /etc/resolv.conf'
] %}

# If no special configuration is set, default to DHCP for all available interfaces.
# Else use the defined config from the pillar.
/etc/network/interfaces:
  file.managed:
    - name: /etc/network/interfaces
{% if pillar['network'] is defined %}
{%   if pillar['network']['interfaces'] is defined %}
    - source: salt://{{ os_path }}/network/etc/network/interfaces.jinja
{%   else %}
    - source: salt://{{ os_path }}/network/etc/network/interfaces.dhcp_default.jinja
{%   endif %}
{% else %}
    - source: salt://{{ os_path }}/network/etc/network/interfaces.dhcp_default.jinja
{% endif %}
    - template: jinja
    - user: root
    - group: root
    - mode: 644

# Make the routing persistant
# These files will be called as scripts from network/interfaces.
{% if pillar['network'] is defined %}
{%   if pillar['network']['routes'] is defined %}
{%     for iface, routes in pillar['network']['routes'].iteritems() %}
/etc/network/if-up.d/routes-{{ iface }}:
  file.managed:
    - name: /etc/network/if-up.d/routes-{{ iface }}
    - source: salt://{{ os_path }}/network/etc/network/if-up.d/routes-add.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - context:
      iface: {{ iface }}
      routes: {{ routes }}

/etc/network/if-down.d/routes-{{ iface }}:
  file.managed:
    - name: /etc/network/if-down.d/routes-{{ iface }}
    - source: salt://{{ os_path }}/network/etc/network/if-down.d/routes-del.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - context:
      iface: {{ iface }}
      routes: {{ routes }}
{%     endfor %}

# When changes to the config where made, the interface needs to restart in order to make the changes count
{%     for iface, routes in pillar['network']['routes'].iteritems() %}
cmd-restart-iface-{{ iface }}:
  cmd.run:
    - name: '/sbin/ip link set {{ iface }} down; /sbin/ip link set {{ iface }} up'
    - runas: root
    - onchanges:
      - file: /etc/network/interfaces
      - file: /etc/network/if-up.d/routes-{{ iface }}
      - file: /etc/network/if-down.d/routes-{{ iface }}
{%     endfor %}
{%   endif %}


# Sometimes the default route gets lost on config changes. Don't know why yet.
# Quick and dirty solution: just readd it.
{%   if pillar['network']['default_gateway'] is defined %}
cmd-add-default-route:
  cmd.run:
    - name: 'ip route add default via {{ pillar['network']['default_gateway'] }}'
    - chk_cmd:
      - '/sbin/route -n | /bin/grep "0.0.0.0" | /bin/grep "{{ pillar['network']['default_gateway'] }}"'
    - runas: root
    - onchanges:
      - cmd: cmd-restart-iface-*
{%   endif %}

# Set DNS-Servers to use.
{%   if pillar['network']['dns_servers'] is defined %}
/etc/resolv.conf:
  file.managed:
    - name: '/etc/resolv.conf'
    - source: 'salt://{{ os_path }}/network/etc/resolv.conf.jinja'
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - context:
      dns_servers: {{ pillar['network']['dns_servers'] }}
{%     if pillar['network']['domain'] is defined %}
      domain: {{ pillar['network']['domain'] }}
{%     endif %}
{%     if pillar['network']['search'] is defined %}
      search: {{ pillar['network']['search'] }}
{%     endif %}
{%   endif %}
{% endif %}

{% if pillar['network'] is not defined %}
notification-network:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# network:
#   pillar_version: '0.0.2'
#   
#   default_gateway: '192.168.1.1'
#
#   dns_servers:
#     - '192.168.1.1'
#     - '8.8.8.8'
#   doamin: 'example.com'
#   search: 'example.com'
#     
#   interfaces:
#     eth0:
#       comments:
#         - 'The primary network interface'
#       auto: True
#       hotplug: True
#       mode: 'static'
#       ipv4addr: '192.168.1.5'
#       netmaskv4: '255.255.255.0'
#       gatewayv4: '192.168.1.1'
#       
#     enp0s8:
#       comments:
#         - 'Secondary Network-Device'
#         - 'With Multiline comment'
#       auto: True
#       hotplug: True
#       mode: 'dhcp'
#       
#   routes:
#     eth0:
#       default:
#         netaddrv4: '0.0.0.0'
#         netmaskv4: '0.0.0.0'
#         gatewayv4: '192.168.1.1'
#       link-local:
#         netaddrv4: '169.254.0.0'
#         netmaskv4: '255.255.0.0'
#         gatewayv4: '0.0.0.0'
#       LAN:
#         netaddrv4: '192.168.1.0'
#         netmaskv4: '255.255.255.0'
#         gatewayv4: '0.0.0.0'
