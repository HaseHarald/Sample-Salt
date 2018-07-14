# ejabberd - distributed, fault-tolerant Jabber/XMPP server

{% set state_version = '0.0.2' %}
{% if pillar['ejabberd'] is defined %}
{%   set pillar_version = pillar['ejabberd'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [] %}

pkg-ejabberd:
  pkg.installed:
    - name: ejabberd
    
srv-ejabberd:
  service.running:
    - name: ejabberd
    - enable: True
    - require:  
      - pkg: pkg-ejabberd
      
{% if pillar['ejabberd'] is defined %}
{%   set etckeeper_watchlist = [
    'file: /etc/ejabberd/ejabberd.yml'
  ] %}
/etc/ejabberd/ejabberd.yml:
  file.managed:
    - name: /etc/ejabberd/ejabberd.yml
    - source: salt://{{ os_path }}/ejabberd/etc/ejabberd/ejabberd.yml.jinja
    - template: jinja
    - user: root
    - group: ejabberd
    - mode: 644
    - watch_in:
      - service: srv-ejabberd
    - require:
      - pkg: pkg-ejabberd
{% endif %}

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# TODO: Comment samples
# --------------
# ejabberd:
#   pillar_version: 0.0.1
#   
#   loglevel: 5
#   s2s_use_starttls: required
#   s2s_certfile: '/etc/ejabberd/ejabberd.pem'
#   s2s_protocol_options:
#     - 'no_sslv3'
#     - 'no_tlsv1'
#   outgoing_s2s_families:
#     - ipv4
#   outgoing_s2s_timeout: 10000
#   auth_method:
#     - ldap
#   fqdn: 'jabber.example.com'
#   ldap_servers:
#     - 'localhost'
#   ldap_encrypt: none
#   ldap_port: 389
#   ldap_rootdn: 'cn=admin,dc=example,dc=com'
#   ldap_password: 'DemoPasswd'
#   ldap_base: 'dc=example,dc=com'
#   ldap_uids:
#     'foo': 'bar'
#   ldap_filter: '(objectClass=shadowAccount)'
#   ldap_dn_filter: 
#     '(&(objectclass=posixGroup)(cn=jabberusers)(memberUid=%u))': '["cn=jabberusers,ou=Groups,dc=example,dc=com"]'
#   
#   listen:
#     ejabberd_c2s:
#       port: 5222
#       ip: '0.0.0.0'
#       certfile: '/etc/ejabberd/ejabberd.pem'
#       starttls_required: true
#       protocol_options:
#         - 'no_sslv3'
#         - 'no_tlsv1'
#       max_stanza_size: 65536
#       shaper: c2s_shaper
#       access: c2s
#       zlib: 'true'
#       resend_on_timeout: 'if_offline'
#     ejabberd_s2s_in:
#       port: 5269
#       ip: '12.34.56.78'
#       transport: tcp
#     ejabberd_http:
#       port: 5280
#       ip: '0.0.0.0'
#       request_handlers:
#         '/websocket': 'ejabberd_http_ws'
#       web_admin: 'true'
#       http_bind: 'true'
#       http_poll: 'true'
#       register: 'false'
#       captcha: 'true'
#       tls: true
#       certfile: "/etc/ejabberd/ejabberd.pem"
#   
#   host_configs:
#     'jabber.example.com':
#       domain_certfile: '/path/to/example_com.pem'
#   
#   shaper:
#     normal: 50000
#     fast: 1000000
#   
#   admin_users:
#     - 'admin@jabber.example.com'
#     

