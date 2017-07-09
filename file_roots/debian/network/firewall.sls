# Firewall management module
# This will set firewall rules, based on pillar-data.
# !!! IMPORTANT !!!
# Unless you specificly set 'test_mode' to 'False', your firewall rules will be discarded
# every 10 minuits via cron. This is to prevent you from locking out your self.
# Also, unless you set 'save' to 'True', your rules will not be persistent after
# reboot. While in test_mode, 'save' is 'False' by default.

{% set state_version = '0.0.3' %}
{% if pillar['firewall'] is defined %}
{%   set pillar_version = pillar['firewall'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/cron.d/reset-iptables'
] %}

# Install required packages for firewalling      
include:
  - debian.network.firewalling-pkgs

# Have the netfilter daemon running
netfilter-persistent.service:
  service.running:
    - name: netfilter-persistent
    - enable: True
    - require:
      - pkg: netfilter-persistent

# Have a reset-script at hand when needed is a good idea
/usr/local/sbin/reset_iptables.sh:
  file.managed:
    - name: /usr/local/sbin/reset_iptables.sh
    - source: salt://debian/network/usr/local/sbin/reset_iptables.sh
    - user: root
    - group: root
    - mode: 750

{% if pillar['firewall'] is defined %}

{%   set save = pillar['firewall'].get('save', 'False') %}
{%   set test_mode = pillar['firewall'].get('test_mode', 'True') %}
{%   if test_mode %}
# When we are in test_mode, we don't want the rules to be persistant
{%     set save = 'False' %}
# ... and we want to clear all firewall-rules every 10 minutes, so we don't lock
# ourselves out accidantily.
/etc/cron.d/reset-iptables:
  file.managed:
    - name: /etc/cron.d/reset-iptables
    - source: salt://debian/network//etc/cron.d/reset-iptables
    - user: root
    - group: root
    - mode: 644

{%   else %}

# When we are not in test_mode, we don't want to reset our firewall.
/etc/cron.d/reset-iptables:
  file.absent:
    - name: /etc/cron.d/reset-iptables

{%   endif %}

{%   if pillar['firewall']['strict_mode'] %}
# If the firewall is set to strict mode, we'll need to allow some connections
# that always need access to anything
allow_localhost:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - source: 127.0.0.1
    - save: {{ save }}
    - require:
      - pkg: iptables.pkgs

# Allow related/established sessions on input
allow_established_INPUT:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: ACCEPT
    - match: conntrack
    - ctstate: 'RELATED,ESTABLISHED'
    - save: {{ save }}
    - require:
      - pkg: iptables.pkgs

# Allow related/established sessions at forward
allow_established_FORWARD:
  iptables.append:
    - table: filter
    - chain: FORWARD
    - jump: ACCEPT
    - match: conntrack
    - ctstate: 'RELATED,ESTABLISHED'
    - save: {{ save }}
    - require:
      - pkg: iptables.pkgs

# Set the policy to deny everything unless defined
enable_reject_INPUT_policy:
  iptables.set_policy:
    - table: filter
    - chain: INPUT
    - policy: DROP
    - require:
      - pkg: iptables.pkgs
      - iptables: allow_localhost
      - iptables: allow_established_INPUT
      - iptables: allow_established_FORWARD
    - save: {{ save }}

# Set the policy to deny everything unless defined
enable_reject_FORWARD_policy:
  iptables.set_policy:
    - table: filter
    - chain: FORWARD
    - policy: DROP
    - require:
      - pkg: iptables.pkgs
      - iptables: allow_localhost
      - iptables: allow_established_INPUT
      - iptables: allow_established_FORWARD
    - save: {{ save }}
{%   endif %}

{%   if pillar['firewall']['blacklist'] is defined %}
{%     for address in pillar['firewall']['blacklist'] %}
# For IPs on the blacklist, block everything
blacklist_INPUT_{{ address }}:
  iptables.append:
    - table: filter
    - chain: INPUT
    - jump: REJECT
    - source: {{ address }}
    - save: {{ save }}
    - require:
      - pkg: iptables.pkgs
{%       if pillar['firewall']['strict_mode'] %}
      - iptables: allow_localhost
      - iptables: allow_established_INPUT
      - iptables: allow_established_FORWARD
{%       endif %}
{%     endfor %}
{%   endif %}

{%   if pillar['firewall']['filter'] is defined %}
{%     for chain in pillar['firewall']['filter'] %}
{%       for comment in pillar['firewall']['filter'][chain] %}
{%         set rule = pillar['firewall']['filter'][chain][comment] %}
# Build custom rule sets and apply them
add_custom_filter_rule_{{ comment }}:
  iptables.append:
    - table: filter
    - chain: {{ chain }}
{%         if rule['source'] is defined %}
    - source: {{ rule['source'] }}
{%         endif %}
{%         if rule['siface'] is defined %}
    - i: {{ rule['siface'] }}
{%         endif %}
{%         if rule['sport'] is defined %}
    - sport: {{ rule['sport'] }}
{%         endif %}
{%         if rule['dest'] is defined %}
    - destination: {{ rule['dest'] }}
{%         endif %}
{%         if rule['oiface'] is defined %}
    - o: {{ rule['oiface'] }}
{%         endif %}
{%         if rule['dport'] is defined %}
    - dport: {{ rule['dport'] }}
{%         endif %}
{%         if rule['proto'] is defined %}
    - proto: {{ rule['proto'] }}
{%         endif %}
{%         if rule['match'] is defined %}
    - match: {{ rule['match'] }}
{%         endif %}
{%         if rule['ctstate'] is defined %}
    - ctstate: {{ rule['ctstate'] }}
{%         endif %}
    - jump: {{ rule['jump'] }}
    - save: {{ save }}
    - require:
      - pkg: iptables.pkgs
{%         if pillar['firewall']['strict_mode'] %}
      - iptables: allow_localhost
      - iptables: allow_established_INPUT
      - iptables: allow_established_FORWARD
{%         endif %}
{%       endfor %}
{%     endfor %}
{%   endif %}
{% else %}

notification-ssh-server:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% include "debian/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# firewall:
#   pillar_version: '0.0.1'
#   strict_mode: True # Drop everything, that doesn't have a whitelisted rule.
#   save: False # Determine wether the rules are persistant after reboot or not
#   test_mode: True # When True or not set at all, delete firewall rules every 10 minuits
#   blacklist:
#     # Every IP listed here will be blocked on INPUT for all ports and all protocolls
#     - '1.2.3.4'
#     - '2.3.4.5'
#
#   filter:
#     # Regular filter rules.
#     # First determine the chain
#     INPUT:
#       # give the rule a name
#       http_global:
#         # and define the params
#         source: '0.0.0.0/0'
#         dport: 80
#         proto: tcp
#         jump: 'ACCEPT'
#       sample:
#         # This should give an overview of the available parameters, not all of
#         # them make sense in this example.
#         # All but 'jump' are kind of optional. Offcourse, no other arguments
#         # would be kind of pointless.
#         source: '192.168.1.42'
#         siface: enp0s3
#         sport: '1025:65535'
#         dest: '192.168.1.23'
#         oiface: enp0s8
#         dport: 22
#         proto: tcp
#         match: 'conntrack'
#         ctstate: 'NEW'
#         jump: 'REJECT'
#
#     FORWARD:
#       # Just have a sample for a different chain
#       LAN_to_WAN:
#         source: '192.168.1.0/24'
#         dest: '0.0.0.0/0'
#         jump: 'ACCEPT'
