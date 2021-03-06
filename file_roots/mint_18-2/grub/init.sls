#grub - configure grub

{% set state_version = '0.0.4' %}
{% if pillar['grub'] is defined %}
{%   set pillar_version = pillar['grub'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/default/grub'
] %}

{% if pillar['grub'] is defined %}
/etc/default/grub:
  file.managed:
    - name: /etc/default/grub
    - source: salt://mint_18-2/grub/etc/default/grub.jinja
    - template: jinja
    - user: root
    - group: root
    - defaults:
      default: 0
      timeout: 10
      cmdline_linux_default: 'quiet splash'
      cmdline_linux: ''
    - context:
{%   if pillar['grub']['default'] is defined %}
      default: {{ pillar['grub']['default'] | yaml_encode }}
{%   endif %}
{%   if pillar['grub']['timeout'] is defined %}
      timeout: {{ pillar['grub']['timeout'] }}
{%   endif %}
{%   if pillar['grub']['cmdline_linux_default'] is defined %}
      cmdline_linux_default: {{ pillar['grub']['cmdline_linux_default'] }}
{%   endif %}
{%   if pillar['grub']['cmdline_linux'] is defined %}
      cmdline_linux: {{ pillar['grub']['cmdline_linux'] }}
{%   endif %}

cmd-update-grub:
  cmd.wait:
    - user: root
    - name: update-grub
    - watch:
      - file: /etc/default/grub

{% else %}
notification-grub:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

{% include "mint_18-2/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# grub:
#   pillar_version: '0.0.1'
#   default: '"Windows 7 (loader) (auf /dev/sda1)"'
#   timeout: 5
#   cmdline_linux_default: 'rootflags=degraded quiet'
#   cmdline_linux: 'rootflags=degraded'
