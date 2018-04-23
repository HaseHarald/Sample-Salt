# ldap-add_MemberOf - Add the possibility to use the "memberof" filter
# This will also automaticly include the referential_integrity-schema.

{% set state_version = '0.1.3' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
    'file: /etc/ldap/schema/memberof.ldif',
    'cmd: ldapadd-memberof.ldif'
  ] %}

/etc/ldap/schema/memberof.ldif:
  file.managed:
    - name: /etc/ldap/schema/memberof.ldif
    - source: salt://{{ os_path }}/ldap//etc/ldap/schema/memberof.ldif
    - require:
      - pkg: pkg-ldap-slapd

ldapadd-memberof.ldif:
  cmd.run:
    - name: ldapadd -Q -Y EXTERNAL -H ldapi:/// -c -f /etc/ldap/schema/memberof.ldif
    - unless: 'ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config olcModuleLoad=memberof | grep -i "olcModuleLoad: " | grep -i "memberof"'
    - watch:
      - file: /etc/ldap/schema/memberof.ldif
    - watch_in:
      - service: service-slapd
    - require:
      - pkg: pkg-ldap-slapd
    - prereq:
      - cmd: ldapmodify-refint_mod.ldif
      - cmd: ldapadd-refint_add.ldif
      
include:
  - {{ os_path }}.ldap.schema.referential_integrity
  
{% include os_path ~ "/etckeeper/commit.sls" %}


