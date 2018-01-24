# issue - have some additional information in the login prompt

{% set state_version = '0.0.3' %}
{% if pillar['etc-issue'] is defined %}
{%   set pillar_version = pillar['etc-issue'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/issue'
] %}

/etc/issue:
  file.managed:
    - name: /etc/issue
    - source: salt://raspbian/stuff/etc/issue.jinja
    - template: jinja

{% if pillar['etc-issue'] is not defined %}
notification-etc/issue:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% include "raspbian/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# etc-issue:
#   pillar_version: '0.0.1'
#   interfaces:
#     - eth0
#     - eth1
#     - wlan0
