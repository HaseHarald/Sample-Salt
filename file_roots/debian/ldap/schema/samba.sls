# ldap-samba - modify ldap for usage with samba

{% set state_version = '0.0.7' %}
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
  'cmd: ldapmodify-samba_indices.ldif'
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

{% include os_path ~ "/etckeeper/commit.sls" %}
