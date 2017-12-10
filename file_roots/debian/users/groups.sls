# Manage groups

{% set state_version = '0.0.5' %}
{% if pillar['groups'] is defined %}
{%   set pillar_version = pillar['groups'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'group: group_*'
] %}

{% if pillar['groups'] is defined %}

{%   for group in pillar['groups'] if not group == 'pillar_version' %}
{%     set args = pillar['groups'][group] %}
group_{{ group }}:
  group.present:
    - name: {{ group }}
{%     if args['gid'] is defined %}
    - gid: {{ groups['gid'] }}
{%     endif %}
{%   endfor %}

{%   include "debian/etckeeper/commit.sls" %}

{% else %}
notification-groups:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}


# Pillar Example
# --------------
# groups:
#   pillar_version: '0.0.1'
#   admin:        # Name of the group
#     gid: 12345  # [optional] defaults to system behavior
#   foo:
#   bar:
#     gid: 42
