#rdate - set the system's date from a remote host

{% set state_version = '0.0.1' %}
{% if pillar['rdate'] is defined %}
{%   set pillar_version = pillar['rdate'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/cron.d/rdate'
] %}

pkg-rdate:
  pkg.installed:
    - name: rdate

{% if pillar['rdate'] is defined %}
{%   if pillar['rdate']['server'] is defined %}
/etc/cron.d/rdate:
  file.managed:
    - name: /etc/cron.d/rdate
    - source: salt://mint_18-2/rdate/etc/cron.d/rdate.jinja
    - template: jinja
    - user: root
    - group: root
    - require:
      - pkg: pkg-rdate
    - defaults:
      minute: 25
      hour: '*/6'
      dom: '*'
      mon: '*'
      dow: '*'
    - context:
{%     if pillar['rdate']['minute'] is defined %}
      minute: {{ pillar['rdate']['minute'] }}
{%     endif %}
{%     if pillar['rdate']['hour'] is defined %}
      hour: {{ pillar['rdate']['hour'] }}
{%     endif %}
{%     if pillar['rdate']['dom'] is defined %}
      dom: {{ pillar['rdate']['dom'] }}
{%     endif %}
{%     if pillar['rdate']['mon'] is defined %}
      mon: {{ pillar['rdate']['mon'] }}
{%     endif %}
{%     if pillar['rdate']['dow'] is defined %}
      dow: {{ pillar['rdate']['dow'] }}
{%     endif %}
      server: {{ pillar['rdate']['server'] }}
{%   endif %}

{% else %}
notification-rdate:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

{% include "mint_18-2/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# rdate:
#   pillar_version: '0.0.1'
#   minute: 42
#   hour: '*/12'
#   dom: '*'
#   mon: '*'
#   dow: '0,2,4,6'
#   server: '0.pool.ntp.org'
