# backup the data from ldap

{% set state_version = '0.0.2' %}
{% if pillar['backup_ldap'] is defined %}
{%   set pillar_version = pillar['backup_ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'file: /etc/cron.d/backup_ldap'
] %}

/usr/local/sbin/backup_ldap.sh:
  file.managed:
    - name: /usr/local/sbin/backup_ldap.sh
    - source: salt://{{ os_path }}/backup/usr/local/sbin/backup_ldap.sh.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 740
    - require:
      - pkg: pkg-ldap-slapd
      - test: pillar-test-backup-ldap
    - context:
{% if pillar['backup_ldap'] is defined %}
{%   if pillar['backup_ldap']['backup_path'] is defined %}
      backup_path: {{ pillar['backup_ldap']['backup_path'] }}
{%   endif %}
      domain: {{ pillar['backup_ldap'].get('domain', 'main.db') }}
{% endif %}

/etc/cron.d/backup_ldap:
  file.managed:
    - name: /etc/cron.d/backup_ldap
    - source: salt://{{ os_path }}/backup/etc/cron.d/backup_ldap.jinja
    - template: jinja
    - user: root
    - group: root
    - require:
      - file: /usr/local/sbin/backup_ldap.sh
    - defaults:
      minute: '45'
      hour: '22'
      dom: '*'
      mon: '*'
      dow: '*'
    - context:
{% if pillar['backup_ldap'] is defined %}
{%   if pillar['backup_ldap']['minute'] is defined %}
      minute: '{{ pillar['backup_ldap']['minute'] }}'
{%   endif %}
{%   if pillar['backup_ldap']['hour'] is defined %}
      hour: '{{ pillar['backup_ldap']['hour'] }}'
{%   endif %}
{%   if pillar['backup_ldap']['dom'] is defined %}
      dom: '{{ pillar['backup_ldap']['dom'] }}'
{%   endif %}
{%   if pillar['backup_ldap']['mon'] is defined %}
      mon: '{{ pillar['backup_ldap']['mon'] }}'
{%   endif %}
{%   if pillar['backup_ldap']['dow'] is defined %}
      dow: '{{ pillar['backup_ldap']['dow'] }}'
{%   endif %}
{% endif %}

pillar-test-backup-ldap:
{% if pillar['backup_ldap'] is defined and
     pillar['backup_ldap']['backup_path'] is defined %}
  test.succeed_without_changes:
    - name: ldap-tools_pillar-test-ldap-admin_pw
{% else %}
  test.fail_without_changes:
    - name: ldap-tools_pillar-test-ldap-admin_pw
{% endif %}

notification-backup_ldap:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
    - onfail:
      - test: pillar-test-backup-ldap

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# backup_ldap:
#   pillar_version: '0.0.1'
#   
#   # Note that this backup probably contains verry sensible data. You will want to chose the backup path wisely.
#   backup_path: '/export/backup' # The path where the backup should be placed to
#   domain: 'example.com' # Optional, Defaults to 'main.db' - The domain of the main database
#
#   # Optional, Defaults to 22:45 every day - Time settings for cron.
#   minute: '42'
#   hour: '22'
#   dom: '*'
#   mon: '*'
#   dow: '0,2,4,6'
# 
