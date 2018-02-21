# LDAP-Tools - Tools for managing a Lightweight Directory Access Protocol Server

{% set state_version = '0.1.5' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'pkg: pkgs-ldap-tools',
  'file: /etc/ldapscripts/ldapscripts.conf',
  'cmd: /etc/ldapscripts/ldapscripts.passwd'
] %}

pkgs-ldap-tools:
  pkg.installed:
    - pkgs:
      - ldap-utils
      - ldapscripts

/etc/ldapscripts/ldapscripts.conf:
  file.managed:
    - name: /etc/ldapscripts/ldapscripts.conf
    - source: salt://{{ os_path }}/ldap/etc/ldapscripts/ldapscripts.conf.jinja
    - template: jinja
    - defaults:
      binddn: 'cn=Manager,dc=example,dc=com'
      gidstart: 10000
      uidstart: 10000
      midstart: 20000
      createhomes: 'no'
    - context: 
{% if pillar['ldap'] is defined %}
{%   if pillar['ldap']['server_url'] is defined %}
      server: {{ pillar['ldap']['server_url'] }}
{%   endif %}
{%   if pillar['ldap']['base_dn'] is defined %}
      suffix: {{ pillar['ldap']['base_dn'] }}
{%   endif %}
      binddn: {{ pillar['ldap'].get('admin_dn', 'cn=Manager,dc=example,dc=com') }}
{%   if pillar['ldap']['ldapscripts'] is defined %}
{%     if pillar['ldap']['ldapscripts']['gsuffix'] is defined %}
      gsuffix: {{ pillar['ldap']['ldapscripts']['gsuffix'] }}
{%     endif %}
{%     if pillar['ldap']['ldapscripts']['usuffix'] is defined %}
      usuffix: {{ pillar['ldap']['ldapscripts']['usuffix'] }}
{%     endif %}
{%     if pillar['ldap']['ldapscripts']['msuffix'] is defined %}
      msuffix: {{ pillar['ldap']['ldapscripts']['msuffix'] }}
{%     endif %}
{%     if pillar['ldap']['ldapscripts']['saslauth'] is defined %}
      saslauth: {{ pillar['ldap']['ldapscripts']['saslauth'] }}
{%     endif %}
      gidstart: {{ pillar['ldap']['ldapscripts'].get('gidstart', 10000) }}
      uidstart: {{ pillar['ldap']['ldapscripts'].get('uidstart', 10000) }}
      midstart: {{ pillar['ldap']['ldapscripts'].get('midstart', 20000) }}
      createhomes: '{{ pillar['ldap']['ldapscripts'].get('createhomes', 'no') }}'
{%   endif %}
{% endif %}
    - require:
      - pkg: pkgs-ldap-tools
      
/etc/ldapscripts/ldapscripts.passwd:
  cmd.run:
    - name: "echo -n {{ pillar['ldap']['admin_pw'] }} > /etc/ldapscripts/ldapscripts.passwd; chown root:root /etc/ldapscripts/ldapscripts.passwd; chmod 400 /etc/ldapscripts/ldapscripts.passwd"
    - unless: "grep -x {{ pillar['ldap']['admin_pw'] }} /etc/ldapscripts/ldapscripts.passwd"
    - user: root
    - require:
      - pkg: pkgs-ldap-tools
      - test: pillar-test-ldap-admin_pw

pillar-test-ldap-admin_pw:
{% if pillar['ldap']['admin_pw'] is defined %}
  test.succeed_without_changes:
    - name: ldap-tools_pillar-test-ldap-admin_pw
{% else %}
  test.fail_without_changes:
    - name: ldap-tools_pillar-test-ldap-admin_pw
{% endif %}

notification-ldap-tools:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
    - onfail:
      - test: pillar-test-ldap-admin_pw

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# ldap:
#   pillar_version: '0.0.1'
#   
#   # Some general configuration, that will be used in several states.
#   base_dn: 'dc=example,dc=com' # Optional, No default value
#   admin_dn: 'cn=admin,dc=example,dc=com' # Optional, Defaults to 'cn=Manager,dc=example,dc=com' - The DN of the admin account.
#   admin_pw: 'TopSecret' # The Password for the admin-dn
#   server_url: 'ldap://localhost' # Optional, No default value
# 
#   # The configuration of ldapscripts.
#   ldapscripts:
#     gsuffix: 'ou=Groups' # Optional, Defaults to 'ou=Groups' - The name of the group-OU
#     usuffix: 'ou=Users' # Optional, Defaults to 'ou=Users' - The name of the user-OU
#     msuffix: 'ou=Computers' # Optional, Defaults to 'ou=Computers' - The name of the machine-OU
#     saslauth: 'GSSAPI' # Optional, Defaults to empty string - Whether or not and which SASL-Auth mechanism to use
#     gidstart: 10000 # Optional, Defaults to 10000 - The GID to start with, when adding groups
#     uidstart: 10000 # Optional, Defaults to 10000 - The UID to start with, when adding users
#     midstart: 20000 # Optional, Defaults to 20000 - The MID to start with, when adding computers
#     createhomes: 'no' # !!! DON'T FORGETT THE QUOTES !!! Optional, Defaults to 'no' - Whether or not to create a home folder for new users.
# 
