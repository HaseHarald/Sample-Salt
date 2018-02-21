# OpenLDAP - Lightweight Directory Access Protocol Server

{% set state_version = '0.1.5' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'pkg: pkg-ldap-slapd',
  'file: /etc/default/slapd'
] %}

pkg-ldap-slapd:
  pkg.installed:
    - name: slapd
    - require:
      - pkg: pkgs-ldap-tools
      - file: /etc/ldapscripts/ldapscripts.conf

service-slapd:    
  service.running:
    - name: slapd
    - enable: True
    - watch:
      - file: /etc/default/slapd
    - require:
      - pkg: pkg-ldap-slapd

/etc/default/slapd:
  file.managed:
    - name: /etc/default/slapd
    - source: salt://{{ os_path }}/ldap/etc/default/slapd.jinja
    - template: jinja
    - defaults:
      slapd_conf: ''
      slapd_user: 'openldap'
      slapd_group: 'openldap'
      slapd_services: 'ldap:/// ldapi:///'
      slapd_options: ''
    - context:
{% if pillar['ldap'] is defined %}
{%   if pillar['ldap']['slapd'] is defined %}
{%     if pillar['ldap']['slapd']['slapd_conf'] is defined %}
      slapd_conf: {{ pillar['ldap']['slapd']['slapd_conf'] }}
{%     endif %}
{%     if pillar['ldap']['slapd']['slapd_user'] is defined %}
      slapd_user: {{ pillar['ldap']['slapd']['slapd_user'] }}
{%     endif %}
{%     if pillar['ldap']['slapd']['slapd_group'] is defined %}
      slapd_group: {{ pillar['ldap']['slapd']['slapd_group'] }}
{%     endif %}
{%     if pillar['ldap']['slapd']['slapd_services'] is defined %}
      slapd_services: {{ pillar['ldap']['slapd']['slapd_services'] }}
{%     endif %}
{%     if pillar['ldap']['slapd']['slapd_options'] is defined %}
      slapd_options: {{ pillar['ldap']['slapd']['slapd_options'] }}
{%     endif %}
{%   endif %}
{% endif %}
    - require:
      - pkg: pkg-ldap-slapd

debconf-slapd:
  debconf.set:
    - name: slapd
    - data:
        "slapd/password1": {"type": "password", "value": "{{ pillar['ldap']['admin_pw'] }}"}
        "slapd/password2": {"type": "password", "value": "{{ pillar['ldap']['admin_pw'] }}"}
        "slapd/domain": {"type": "string", "value": "{{ pillar['ldap']['slapd']['domain'] }}"}
        "slapd/backend": {"type": 'select', "value": "{{ pillar['ldap']['slapd'].get('backend', 'MDB') }}"}
        "slapd/no_configuration": {"type": "boolean", "value": {{ pillar['ldap']['slapd'].get('no_configuration', False) }}}
        "slapd/move_old_database": {"type": "boolean", "value": {{ pillar['ldap']['slapd'].get('move_old_db', True) }}}
        "shared/organization": {"type": "string", "value": "{{ pillar['ldap']['slapd']['organization'] }}"}
        "slapd/purge_database": {"type": "boolean", "value": {{ pillar['ldap']['slapd'].get('purge_database', False) }}}
        "slapd/dump_database": {"type": 'select', "value": "{{ pillar['ldap']['slapd'].get('dumpdb_on_update', 'when needed') }}"}
        "slapd/dump_database_destdir": {"type": "string", "value": "{{ pillar['ldap']['slapd'].get('dumpdb_destdir', '/var/backups/slapd-VERSION')}}"}
        "slapd/invalid_config": {"type": "boolean", "value": False} # since this is non-interactive, there is no use in making this actually configurable
        "slapd/ppolicy_schema_needs_update": {"type": 'select', "value": "{{ pillar['ldap']['slapd'].get('ppolicy_schema_needs_update', 'abort installation') }}"}
{% if pillar['ldap']['slapd']['internal_passwd'] is defined %}
        "slapd/internal/adminpw": {"type": "password", "value": "{{ pillar['ldap']['slapd']['internal_passwd'] }}"}
        "slapd/internal/generated_adminpw": {"type": "password", "value": "{{ pillar['ldap']['slapd']['internal_passwd'] }}"}
{% endif %}
    - prereq:
      - pkg: pkg-ldap-slapd
    - require:
      - test: pillar-test-ldap-slapd

pillar-test-ldap-slapd:
{% if pillar['ldap'] is defined and
     pillar['ldap']['admin_pw'] is defined and
     pillar['ldap']['slapd'] is defined and
     pillar['ldap']['slapd']['domain'] is defined and
     pillar['ldap']['slapd']['organization'] is defined %}
  test.succeed_without_changes:
    - name: ldap_pillar-test-ldap-slapd
{% else %}
  test.fail_without_changes:
    - name: ldap_pillar-test-ldap-slapd
{% endif %}

include:
{% if pillar['ldap']['schema'] is defined %}
{%   for schema in pillar['ldap']['schema'] %}
  - {{ os_path }}.ldap.schema.{{ schema }}
{%   endfor %}
{% endif %}

notification-sldapd:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
    - onfail:
      - test: pillar-test-ldap-slapd

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# ldap:
#   pillar_version: '0.0.1'
#   
#   # Some general configuration, that will be used in several states.
#   base_dn: 'dc=example,dc=com' # Not used in here, but usefull to set for some other states
#   admin_dn: 'cn=admin,dc=example,dc=com' # Not used in here, but usefull to set for some other states
#   admin_pw: 'TopSecret' # The Password for the admin-dn
#   server_url: 'ldap://localhost' # Not used in here, but usefull to set for some other states
#   
#   # slpad sepcific configuration
#   slapd:
#     domain: 'example.com' # Do NOT use dc=example,dc=net notation! Causes dpkg to hang!
#     backend: 'MDB' # Optional, Defaults to MDB - The database backend for LDAP. Possible Values are BDB, HDB and MDB.
#     no_configuration: False # Optional, Defaults to False - Whether or not an initial configuration and database should be created.
#     move_old_db: True # Optional, Defaults to True - Whether or not to move an allready existing DB upon installation if one exists.
#     organization: 'Example and Partners Co.'
#     purge_database: True # Optional, Defaults to False - Do you want the database to be removed when slapd is purged?
#     dumpdb_on_update: 'when needed' # Optional, Defaults to 'when needed' - Dump the database on slapd update? Possible values are 'always', 'when needed' and 'never'.
#     dumpdb_destdir: '/var/backups/slapd-VERSION' # Optional, Defaults to '/var/backups/slapd-VERSION' - Where to dump the database
#     ppolicy_schema_needs_update: 'continue regardless' # Optional, Defaults to 'abort installation' - What to do, when password policys don't match upon update. Possible values are 'abort installation' and 'continue regardless'.
#     internal_passwd: 'internpw' # Optional, Defaults to random - Encrypted Admin-Password. You probably don't need this.
#     slapd_conf: '' # Optional, Defaults to empty string - Location of the slapd.conf, if empty uses compiled in default.
#     slapd_user: 'openldap' # Optional, Defaults to openldap - What user to run the slapd process on
#     slapd_group: 'openldap' # Optional, Defaults to openldap - What group to run the slapd service on
#     slapd_services: 'ldap:/// ldapi:///' # Optional, Defaults to 'ldap:/// ldapi:///' - Which services to offer
#     slapd_options: '' # Optional, Defaults to empty string - Additional options to pass to slapd
#     tls_expiration_days: 3650 # Optional, Defaults to 3650 - Number of days untill the tls-cert for the ldap server expires. Only used if secureldap module is loaded.
# 
#   # You can define and configure andditional schemas here, that will automaticly be included.
#   # Note that there are some schemas, that don't need additional configuration and therefore are just listed here.
#   # For details on hwo to configure those schemas that do need configuration, look at the statefile of the specified schema.
#   # This whole section and all of its schemas are optional.
#   schema:
#     logging:
#       log-level: 'parse shell config'
#     CORBA:
#     ou_UsersGroups:
#     samba:
