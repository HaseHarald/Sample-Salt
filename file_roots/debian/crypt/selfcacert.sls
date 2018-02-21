# selfcacert - install all necessary tools to create a self signed ca-cert and do this.

{% set state_version = '0.0.1' %}
{% if pillar['selfcacert'] is defined %}
{%   set pillar_version = pillar['selfcacert'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'pkg: pkgs-certtools',
  'cmd: generate-selfca-privkey',
  'file: /etc/ssl/ca.info',
  'cmd: generate-selfsigned-cacert'
] %}

pkgs-certtools:
  pkg.installed:
    - pkgs:
      - gnutls-bin
      - ssl-cert
      
generate-selfca-privkey:
  cmd.run:
    - name: 'certtool --generate-privkey > /etc/ssl/private/cakey.pem'
    - user: root
    - creates: /etc/ssl/private/cakey.pem
    - require:
      - pkg: pkgs-certtools

{% if pillar['selfcacert'] is defined %}
{%   if pillar['selfcacert']['cn'] is defined %}
/etc/ssl/ca.info:
  file.managed:
    - name: /etc/ssl/ca.info
    - source: salt://{{ os_path }}/crypt/etc/ssl/ca.info.jinja
    - template: jinja
    - context:
      cn: {{ pillar['selfcacert']['cn'] }}

generate-selfsigned-cacert:
  cmd.run:
    - name: 'certtool --generate-self-signed --load-privkey /etc/ssl/private/cakey.pem --template /etc/ssl/ca.info --outfile /etc/ssl/certs/cacert.pem'
    - user: root
    - creates: /etc/ssl/certs/cacert.pem
    - require:
      - pkg: pkgs-certtools
      - cmd: generate-selfca-privkey
      - file: /etc/ssl/ca.info
{%   endif %}
{% else %}

notification-selfcacert:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# selfcacert:
#   pillar_version: '0.0.1'
#   cn: 'Example Company'
