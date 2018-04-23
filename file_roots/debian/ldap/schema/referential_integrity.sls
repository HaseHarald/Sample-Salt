# ldap-add_referential_integrity - Add referential integrity to the ldap config

{% set state_version = '0.1.1' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
    'file: /etc/ldap/schema/refint_mod.ldif',
    'cmd: ldapmodify-refint_mod.ldif',
    'file: /etc/ldap/schema/refint_add.ldif',
    'cmd: ldapadd-refint_add.ldif'
  ] %}

/etc/ldap/schema/refint_mod.ldif:
  file.managed:
    - name: /etc/ldap/schema/refint_mod.ldif
    - source: salt://{{ os_path }}/ldap//etc/ldap/schema/refint_mod.ldif
    - require:
      - pkg: pkg-ldap-slapd

ldapmodify-refint_mod.ldif:
  cmd.run:
    - name: ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/refint_mod.ldif
    - unless: 'ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config olcModuleLoad=refint | grep refint'
    - watch:
      - file: /etc/ldap/schema/refint_mod.ldif
    - watch_in:
      - service: service-slapd
    - require:
      - pkg: pkg-ldap-slapd

/etc/ldap/schema/refint_add.ldif:
  file.managed:
    - name: /etc/ldap/schema/refint_add.ldif
    - source: salt://{{ os_path }}/ldap//etc/ldap/schema/refint_add.ldif
    - require:
      - pkg: pkg-ldap-slapd
      
ldapadd-refint_add.ldif:
  cmd.run:
    - name: ldapadd -Q -Y EXTERNAL -H ldapi:/// -c -f /etc/ldap/schema/refint_add.ldif
    - unless: 'ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config olcOverlay=refint | grep refint'
    - watch:
      - file: /etc/ldap/schema/refint_add.ldif
    - watch_in:
      - service: service-slapd
    - require:
      - pkg: pkg-ldap-slapd
      - cmd: ldapmodify-refint_mod.ldif
      
{% include os_path ~ "/etckeeper/commit.sls" %}


