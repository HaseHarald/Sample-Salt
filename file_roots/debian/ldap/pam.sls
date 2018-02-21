# OpenLDAP - Lightweight Directory Access Protocol Server

{% set state_version = '0.1.2' %}
{% if pillar['ldap'] is defined %}
{%   set pillar_version = pillar['ldap'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'pkg: pkgs-ldap-pam',
  'file: /etc/nsswitch.conf'
] %}

pkgs-ldap-pam:
  pkg.installed:
    - pkgs:
      - libnss-ldap
      - libpam-ldap

/etc/nsswitch.conf:
  file.managed:
    - name: /etc/nsswitch.conf
    - source: salt://{{ os_path }}/ldap/etc/nsswitch.conf
    - require:
      - pkg: pkgs-ldap-pam

debconf-libpam-ldap:
  debconf.set:
    - name: libpam-ldap
    - data:
        "libpam-ldap/rootbinddn": {"type": "string", "value": "{{ pillar['ldap']['admin_dn'] }}"}
        "libpam-ldap/rootbindpw": {"type": "password", "value": "{{ pillar['ldap']['admin_pw'] }}"}
        "libpam-ldap/dblogin": {"type": "boolean", "value": {{ pillar['ldap']['ldap_auth_config'].get('dblogin', False) }}}
        "libpam-ldap/pam_password": {"type": "select", "value": "{{ pillar['ldap']['ldap_auth_config'].get('pam_passwd', 'crypt') }}"} # "choices": "clear, crypt, nds, ad, exop, md5"
        "libpam-ldap/binddn": {"type": "string", "value": "{{ pillar['ldap']['ldap_auth_config']['binddn'] }}"}
        "libpam-ldap/bindpw": {"type": "password", "value": "{{ pillar['ldap']['ldap_auth_config']['bindpw'] }}"}
        "libpam-ldap/dbrootlogin": {"type": "boolean", "value": {{ pillar['ldap']['ldap_auth_config'].get('dbrootlogin', True) }}}
        "libpam-ldap/override": {"type": "boolean", "value": {{ pillar['ldap']['ldap_auth_config'].get('override_libpam_ldap_conf', True) }}}
        "shared/ldapns/ldap_version": {"type": 'select', "value": {{ pillar['ldap']['ldap_auth_config'].get('ldap_version', 3) }}}
        "shared/ldapns/base-dn": {"type": "string", "value": "{{ pillar['ldap']['base_dn'] }}"}
        "shared/ldapns/ldap-server": {"type": "string", "value": "{{ pillar['ldap'].get('server_url', 'ldapi:///') }}"}
    - prereq:
      - pkg: pkgs-ldap-pam
    - require:
      - test: pillar-test-ldap-ldap_auth_config

debconf-libnss-ldap:
  debconf.set:
    - name: libnss-ldap
    - data:
        "libnss-ldap/confperm": {"type": "boolean", "value": {{ pillar['ldap']['ldap_auth_config'].get('restrict_config_permisions', False) }}}
        "libnss-ldap/dblogin": {"type": "boolean", "value": {{ pillar['ldap']['ldap_auth_config'].get('dblogin', False) }}}
        "libnss-ldap/override": {"type": "boolean", "value": {{ pillar['ldap']['ldap_auth_config'].get('override_libnss_ldap_conf', True) }}}
        "libnss-ldap/binddn": {"type": "string", "value": "{{ pillar['ldap']['ldap_auth_config']['binddn'] }}"}
        "libnss-ldap/bindpw": {"type": "password", "value": "{{ pillar['ldap']['ldap_auth_config']['bindpw'] }}"}
        "libnss-ldap/dbrootlogin": {"type": "boolean", "value": {{ pillar['ldap']['ldap_auth_config'].get('dbrootlogin', True) }}}
        "libnss-ldap/rootbinddn": {"type": "string", "value": "{{ pillar['ldap']['admin_dn'] }}"}
        "libnss-ldap/rootbindpw": {"type": "password", "value": "{{ pillar['ldap']['admin_pw'] }}"}
        "shared/ldapns/ldap_version": {"type": 'select', "value": {{ pillar['ldap']['ldap_auth_config'].get('ldap_version', 3) }}}
        "shared/ldapns/base-dn": {"type": "string", "value": "{{ pillar['ldap']['base_dn'] }}"}
        "shared/ldapns/ldap-server": {"type": "string", "value": "{{ pillar['ldap'].get('server_url', 'ldap://127.0.0.1/') }}"}
    - prereq:
      - pkg: pkgs-ldap-pam
    - require:
      - test: pillar-test-ldap-ldap_auth_config

pillar-test-ldap-ldap_auth_config:
{% if pillar['ldap']['base_dn'] is defined and
     pillar['ldap']['admin_dn'] is defined and
     pillar['ldap']['admin_pw'] is defined and
     pillar['ldap']['server_url'] is defined and
     pillar['ldap']['ldap_auth_config'] is defined and
     pillar['ldap']['ldap_auth_config']['binddn'] is defined and
     pillar['ldap']['ldap_auth_config']['bindpw'] is defined %}
  test.succeed_without_changes:
    - name: ldap-pam_pillar-test-ldap-ldap_auth_config
{% else %}
  test.fail_without_changes:
    - name: ldap-pam_pillar-test-ldap-ldap_auth_config
{% endif %}

notification-ldap-pam:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
    - onfail:
      - test: pillar-test-ldap-ldap_auth_config

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
#   server_url: 'ldap://localhost' # Optional, Defaults to 'ldap://127.0.0.1/'
# 
#   # The config of the ldap-pam and libnss-modules.
#   ldap_auth_config:
#     dblogin: False # Optional, Defaults to False - Does the LDAP database require login?
#     pam_passwd: 'crypt' # Optional, Defaults to 'crypt' - Local encryption algorithm to use for passwords. Choices are "clear, crypt, nds, ad, exop, md5"
#     binddn: 'cn=proxyuser,dc=example,dc=net' # Name of the LDAP account that should be used for non-administrative (read-only) database logins.
#     bindpw: ''
#     dbrootlogin: True # Optional, Defaults to True - Allow LDAP admin account to behave like local root
#     override_libpam_ldap_conf: True # Optional, Defaults to True - The resulting configuration file may overwrite local changes.
#     restrict_config_permisions: False # Optional, Defaults to False - Make the configuration file readable/writeable by its owner only
#     ldap_version: 3 # Optional, Defaults to 3 - The version of the LDAP protocoll to use
# 
