# grub - install grub to certain disks

{% set state_version = '0.0.1' %}
{% if pillar['grub_install'] is defined %}
{%   set pillar_version = pillar['grub_install'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [] %}

{% if pillar['grub_install'] is defined %}
{%   for disk in pillar['grub_install'].iteritems() if not user == 'pillar_version' %}
cmd_grub_install_{{ disk }}:
  cmd.wait:
    - name: 'grub-install {{ disk }}
    - user: root
    - watch:
      - sls: mint_18-2.grub
{%   endfor %}

{% else %}
notification-grub_install:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

# Pillar Example
# --------------
# grub:
#   pillar_version: '0.0.1'
#   /dev/sda
#   /dev/disk/by-id/foobar
