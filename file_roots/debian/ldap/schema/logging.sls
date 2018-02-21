# ldap-logging - Set the logging-level of ldap.

{% set state_version = '0.0.5' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'cmd: ldapmodify-logging.ldif'
] %}

{% set log_level = 'none' %}
{% if pillar['ldap']['schema']['logging'] is defined %}
{%   if pillar['ldap']['schema']['logging']['log-level'] is defined %}
{%     set log_level = pillar['ldap']['schema']['logging']['log-level'] %}
{%   else %}
notification-ldap-schmea-logging:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{%   endif %}
{% endif %}

/tmp/logging.ldif:
  file.managed:
    - name: /tmp/logging.ldif
    - source: salt://{{ os_path }}/ldap/tmp/logging.ldif.jinja
    - template: jinja
    - context:
      log_level: {{ log_level }}
    - unless: 'ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config | grep -x "olcLogLevel: {{ log_level }}"'
    - require:
      - pkg: pkg-ldap-slapd

ldapmodify-logging.ldif:
  cmd.wait:
    - name: ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/logging.ldif
    - unless: 'ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config | grep -x "olcLogLevel: {{ log_level }}"'
    - watch:
      - file: /tmp/logging.ldif
    - watch_in:
      - service: service-slapd
    - require:
      - pkg: pkg-ldap-slapd

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# ldap:
#   pillar_version: '0.0.1'
#   
#   # Some general configuration, that will be used in several states.
#   base_dn: 'dc=example,dc=com' # Not used in here, but usefull to set for some other states
#   admin_dn: 'cn=admin,dc=example,dc=com' # Not used in here, but usefull to set for some other states
#   admin_pw: 'TopSecret' # Not used in here, but usefull to set for some other states
#   server_url: 'ldap://localhost' # Not used in here, but usefull to set for some other states
# 
#   schema:
#     logging:
#       log-level: 'parse shell config' # Optional, Defaults to 'none' - The log-level settings. For details see 'man slapd.conf'
# 
