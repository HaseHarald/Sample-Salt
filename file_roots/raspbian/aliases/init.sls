# modify /etc/aliases

{% set state_version = '0.0.1' %}
{% if pillar['aliases'] is defined %}
{%   set pillar_version = pillar['aliases'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'raspbian' %}
{% set etckeeper_watchlist = [
  'file: /etc/aliases',
  'alias: alias-*'
] %}

/etc/aliases:
  file.prepend:
    - name: /etc/aliases
    - header: True
    - text:
      - '# =========================================='
      - '# This file is managed by Salt. Do not edit!'
      - '# =========================================='
      
{% for name, target in salt['pillar.get']('aliases', {}).iteritems() if not name == 'pillar_version' %}
alias-{{ name }}:
  alias.present:
    - name: {{ name }}
    - target: {{ target }}
{% endfor %}

{% if pillar['aliases'] is not defined %}
notification-aliases:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# aliases:
#   pillar_version: 0.0.1
#   foo: 'foo@example.com'
#   bar: 'bar@example.com'
#   foobar: 'foo, bar'
