# ldap-add_OU_UsersGroups - Add Users and Groups as an organisational unit to LDAP

{% set state_version = '0.1.1' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'test: notification-ldap-ou_UsersGroups'
] %}

{% set provided_data = 0 %}

{% if pillar['ldap']['base_dn'] is defined %}
{%   set base_dn = pillar['ldap']['base_dn'] %}
{%   set provided_data = provided_data + 1 %}
{% endif %}

{% if pillar['ldap']['admin_dn'] is defined %}
{%   set admin_dn = pillar['ldap']['admin_dn'] %}
{%   set provided_data = provided_data + 1 %}
{% endif %}

{% if pillar['ldap']['admin_pw'] is defined %}
{%   set admin_pw = pillar['ldap']['admin_pw'] %}
{%   set provided_data = provided_data + 1 %}
{% endif %}

{% if provided_data >= 3 %}
{%   set etckeeper_watchlist = [
       'cmd: ldapadd-add_OU_UsersGroups.ldif'
     ] %}
     
/tmp/add_OU_UsersGroups.ldif:
  file.managed:
    - name: /tmp/add_OU_UsersGroups.ldif
    - source: salt://{{ os_path }}/ldap/tmp/add_OU_UsersGroups.ldif.jinja
    - template: jinja
    - context:
      base_dn: {{ base_dn }}
    - unless: ldapsearch -x -LLL -H ldapi:/// -b {{ base_dn }} olcDbIndex | grep 'ou=Users,{{ base_dn }}'
    - require:
      - pkg: pkg-ldap-slapd

ldapadd-add_OU_UsersGroups.ldif:
  cmd.wait:
    - name: ldapadd -x -H ldapi:/// -f /tmp/add_OU_UsersGroups.ldif -D {{ admin_dn }} -w {{ admin_pw }}
    - unless: ldapsearch -x -LLL -H ldapi:/// -b {{ base_dn }} olcDbIndex | grep 'ou=Users,{{ base_dn }}'
    - watch:
      - file: /tmp/add_OU_UsersGroups.ldif
    - require:
      - pkg: pkg-ldap-slapd

# Sadly this doesn't work:
#/tmp/add_OU_UsersGroups.ldif-remove-on-success:
#/tmp/add_OU_UsersGroups.ldif-remove:
#  file.absent:
#    - name: /tmp/add_OU_UsersGroups.ldif
#    - require:
#      - cmd: ldapadd-add_OU_UsersGroups.ldif
#    - onfail:
#      - cmd: ldapadd-add_OU_UsersGroups.ldif

#/tmp/add_OU_UsersGroups.ldif-remove-on-fail:
#  file.absent:
#    - name: /tmp/add_OU_UsersGroups.ldif
#    - onfail:
#      - cmd: ldapadd-add_OU_UsersGroups.ldif

{% else %}
notification-ldap-schema-ou_UsersGroups:
  test.show_notification:
    - text: {{ 'You need to supply a base-dn and login-data for this state to work. For more informations read the example comment for this state in %s.' % sls }}
{% endif %}

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# ldap:
#   pillar_version: '0.0.1'
#   
#   # Some general configuration, that will be used in several states.
#   base_dn: 'dc=example,dc=com'
#   admin_dn: 'cn=admin,dc=example,dc=com'
#   admin_pw: 'TopSecret'
#   server_url: 'ldap://localhost' # Not used in here, but usefull to set for some other states
# 
