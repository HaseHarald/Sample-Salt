# Manage entries in /etc/hosts

{% set state_version = '0.0.1' %}
{% if pillar['hosts'] is defined %}
{%   set pillar_version = pillar['hosts'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'host: hosts-*'
] %}

hosts-localhost-default:
  host.present:
    - ip: 127.0.0.1
    - names:
      - localhost

{% if pillar['hosts'] is defined %}
{%   for ip in pillar['hosts'] if not ip == 'pillar_version' %}
hosts-{{ ip }}:
{%     set exclusive = pillar['hosts'][ip].get('exlusive', False) %}
{%     if exclusive == True %}
  host.only:
{%     else %}
  host.present:
{%     endif %}
    - ip: {{ ip }}
    - names:
{%     for name in pillar['hosts'][ip]['names'] %}
      - {{ name }}
{%     endfor %}
{%   endfor %}
{% else %}
notification-hosts:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

{% include "debian/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# hosts:
#   pillar_version: '0.0.1'
#   '192.168.0.1':        # The IP-Address to bind the names to
#     names:              # Followed by at least one hostname as a list.
#       - myrouter.lan    # Must be a list, even when only one hostname is given.
#       - localrouter
#     exclusive: True     # Optional, if True, onle the listed names are set for this IP. Default is False.
#   '10.0.0.1':
#     names:
#       - some.other.machine.org
#       - another.example.com
