# grub - install grub to certain disks

{% set state_version = '0.1.2' %}
{% if pillar['grub_install'] is defined %}
{%   set pillar_version = pillar['grub_install'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'mint_18-2' %}
{% set etckeeper_watchlist = [] %}

{% if pillar['grub_install'] is defined %}
{%   for disk in salt['pillar.get']('grub_install:disks', []) %}
cmd_grub_install_{{ disk }}:
  cmd.wait:
    - name: 'grub-install {{ disk }}'
    - user: root
    - watch:
      - sls: {{ os_path }}.grub
{%   endfor %}

{% else %}
notification-grub_install:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

# Pillar Example
# --------------
# grub_install:
#   pillar_version: '0.0.1'
#   disks:
#     - /dev/sda
#     - /dev/disk/by-id/foobar
