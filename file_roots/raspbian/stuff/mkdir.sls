# makes sure a given directory is present

{% set state_version = '0.0.3' %}
{% if pillar['mkdir'] is defined %}
{%   set pillar_version = pillar['mkdir'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'raspbian' %}
{% set etckeeper_watchlist = [
  'file: mkdir-*'
] %}

{% if pillar['mkdir'] is defined %}
{%   for path in pillar['mkdir'] if not path == "pillar_version" %}
mkdir-{{ path }}:
  file.directory:
    - name: {{ path }}
{%     if pillar['mkdir'][path]['user'] is defined %}
    - user: {{ pillar['mkdir'][path]['user'] }}
{%     endif %}
{%     if pillar['mkdir'][path]['group'] is defined %}
    - group: {{ pillar['mkdir'][path]['group'] }}
{%     endif %}
{%     if pillar['mkdir'][path]['mode'] is defined %}
    - mode: {{ pillar['mkdir'][path]['mode'] }}
{%     endif %}
{%     if pillar['mkdir'][path]['makedirs'] is defined %}
    - makedirs: {{ pillar['mkdir'][path]['makedirs'] }}
{%     else %}
    - makedirs: True
{%     endif %}
    - require:
{%     if pillar['groups'] is defined %}
{%       if pillar['mkdir'][path]['group'] is defined %}
{%         if pillar['mkdir'][path]['group'] in pillar['groups'] %}
      - group: group_{{ pillar['mkdir'][path]['group'] }}
{%         endif %}
{%       endif %}
{%     endif %}
{%     if pillar['users'] is defined %}
{%       if pillar['mkdir'][path]['user'] is defined %}
{%         if pillar['mkdir'][path]['user'] in pillar['users'] %}
      - user: user_{{ pillar['mkdir'][path]['user'] }}
{%         endif %}
{%       endif %}
{%     endif %}
{%   endfor %}

{% else %}
notification-mkdir:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

{% include os_path ~ "/etckeeper/commit.sls" %}
