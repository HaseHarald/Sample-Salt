# ldap-samba - modify ldap for usage with samba

{% set state_version = '0.2.1' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'file: /etc/ldap/schema/samba.schema',
  'file: /etc/ldap/schema/samba.ldif',
  'cmd: ldapadd-/etc/ldap/schema/samba.ldif',
  'cmd: ldapmodify-samba_indices.ldif',
  'cmd: ldapadd-smbldap_populate.ldif'
] %}

/etc/ldap/schema/samba.schema:
  file.managed:
    - name: /etc/ldap/schema/samba.schema
    - source: salt://{{ os_path }}/ldap/etc/ldap/schema/samba.schema
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: pkg-ldap-slapd

/etc/ldap/schema/samba.ldif:
  file.managed:
    - name: /etc/ldap/schema/samba.ldif
    - source: salt://{{ os_path }}/ldap/etc/ldap/schema/samba.ldif
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: pkg-ldap-slapd

ldapadd-/etc/ldap/schema/samba.ldif:
  cmd.run:
    - name: ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/samba.ldif
    - unless: ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config 'cn=*samba*' | grep sambaTrustedDomain
    - require:
      - file: /etc/ldap/schema/samba.ldif
      - pkg: pkg-ldap-slapd

/tmp/samba_indices.ldif:
  file.managed:
    - name: /tmp/samba_indices.ldif
    - source: salt://{{ os_path }}/ldap/tmp/samba_indices.ldif
    - unless: 'ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config olcDatabase={1}mdb olcDbIndex | grep sambaSID'
    - prereq:
      - cmd: ldapmodify-samba_indices.ldif

ldapmodify-samba_indices.ldif:
  cmd.run:
    - name: ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/samba_indices.ldif
    - unless: 'ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config olcDatabase={1}mdb olcDbIndex | grep sambaSID'
    - require:
      - pkg: pkg-ldap-slapd
      - cmd: ldapadd-/etc/ldap/schema/samba.ldif

/tmp/smbldap_populate.ldif:
  file.managed:
    - name: /tmp/smbldap_populate.ldif
    - source: salt://{{ os_path }}/ldap/tmp/smbldap_populate.ldif.jinja
    - template: jinja
    - unless: "ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b sambaDomainName={{ salt['pillar.get']('ldap:schema:samba:sambaDomain', 'samba') }},{{ salt['pillar.get']('ldap:base_dn') }} | grep 'sambaSID: {{ salt['pillar.get']('ldap:schema:samba:sambaSID') }}'"
    - prereq:
      - cmd: ldapadd-smbldap_populate.ldif

# TODO: Under certain circumstances, the ldap commands return code is 68 and not 0. Still everything is ok, but Salt will catch this as an error.
ldapadd-smbldap_populate.ldif:
  cmd.run:
    - name: ldapadd -c -x -D {{ salt['pillar.get']('ldap:admin_dn') }} -w {{ salt['pillar.get']('ldap:admin_pw') }} -f /tmp/smbldap_populate.ldif
    - unless: "ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b sambaDomainName={{ salt['pillar.get']('ldap:schema:samba:sambaDomain', 'samba') }},{{ salt['pillar.get']('ldap:base_dn') }} | grep 'sambaSID: {{ salt['pillar.get']('ldap:schema:samba:sambaSID') }}'"
    - require:
      - pkg: pkg-ldap-slapd
      - cmd: ldapadd-/etc/ldap/schema/samba.ldif
      - cmd: ldapmodify-samba_indices.ldif

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# ldap:
#   pillar_version: '0.0.1'
#   
#   # Some general configuration, that will be used in several states.
#   base_dn: 'dc=example,dc=com' # The base-dn of the LDAP-Database
#   admin_dn: 'cn=admin,dc=example,dc=com' # The dn of the database admin
#   admin_pw: 'TopSecret' # The admins password
#   server_url: 'ldap://localhost' # Not used in here, but usefull to set for some other states
# 
#   schema:
#     samba:
#       users_dn: 'ou=Users' # Optional, Defaults to "ou=Users" - The Relative Distinguished Name of the users node
#       groups_dn: 'ou=Groups' # Optional, Defaults to "ou=Groups" - The RDN of the groups node
#       computers_dn: 'ou=Computers' # Optional, Default to "ou=Computers" - The RDN of the machines node
#       idmap_dn: 'ou=Idmap' # Optional, Defaults to "ou=Idmap" - The RDN for the Idmap
#       sambaDomain: 'samba' # Optional, Defaults to 'samba' - The samba domain name
#       sambaSID: 'S-1-2-34-5678901234-567890123-4567890123' # The SID of the samba system. To obtain this number do: "net getlocalsid" on the samba-host.
# 
