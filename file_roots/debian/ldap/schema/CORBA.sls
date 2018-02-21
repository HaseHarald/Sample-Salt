# ldap-CORBA - Add Common Object Request Broker Architecture Model to LDAP

{% set state_version = '0.0.1' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'cmd: ldapadd-corba.ldif'
] %}

ldapadd-corba.ldif:
  cmd.run:
    - name: ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/corba.ldif
    - unless: ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=schema,cn=config dn | grep corba
    - require:
      - pkg: pkg-ldap-slapd

{% include os_path ~ "/etckeeper/commit.sls" %}
