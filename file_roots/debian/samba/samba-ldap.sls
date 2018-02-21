# Samba-LDAP - LDAP access for smb-server

{% set state_version = '0.2.0' %}
{% if pillar['samba'] is defined %}
{%   set pillar_version = pillar['samba'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'debian' %}
{% set etckeeper_watchlist = [
  'pkg: pkg-smbldap-tools',
  'cmd: net-setlocalsid',
  'file: /etc/smbldap-tools/smbldap_bind.conf',
  'file: /etc/smbldap-tools/smbldap.conf'
] %}


{% if salt['cmd.run']("which net") %}
{%   set sid = salt['cmd.run']("net getlocalsid 2>/dev/null | awk -F ':' '{print $2}'").strip() %}
{% else %}
{%   set sid = "" %}
{% endif %}

{% if pillar['samba']['smbldap-tools'] is defined %}

{%   set useTLS = 1 %}

{%   set uidstart = 10000 %}
{%   set gidstart = 10000 %}
{%   set midstart = 10000 %}

{%   if pillar['samba']['smbldap-tools']['uidstart'] is defined %}
{%     set uidstart = pillar['samba']['smbldap-tools']['uidstart'] %}
{%   endif %}
{%   if pillar['samba']['smbldap-tools']['gidstart'] is defined %}
{%     set gidstart = pillar['samba']['smbldap-tools']['gidstart'] %}
{%   endif %}
{%   if pillar['samba']['smbldap-tools']['midstart'] is defined %}
{%     set midstart = pillar['samba']['smbldap-tools']['midstart'] %}
{%   endif %}

{%   if pillar['samba']['smbldap-tools']['smbldap_bind.conf'] is defined %}
/etc/smbldap-tools/smbldap_bind.conf:
  file.managed:
    - name: /etc/smbldap-tools/smbldap_bind.conf
    - source: salt://{{ os_path }}/samba/etc/smbldap-tools/smbldap_bind.conf.jinja
    - template: jinja
    - context:
      masterDN: {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterDN'] }}
      masterPW: {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterPW'] }}
{%     if pillar['samba']['smbldap-tools']['smbldap_bind.conf']['slaveDN'] is defined %}
      slaveDN: {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['slaveDN'] }}
{%     else %}
      slaveDN: {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterDN'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap_bind.conf']['slavePW'] is defined %}
      slavePW: {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['slavePW'] }}
{%     else %}
      slavePW: {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterPW'] }}
{%     endif %}
    - require:
      - pkg: pkg-smbldap-tools

smbpasswd-rootDN:
  cmd.run:
    - name: smbpasswd -w {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterPW'] }}
    - unless: tdbdump /var/lib/samba/private/secrets.tdb | grep {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterPW'] }}
    - require:
      - pkg: pkg-samba
      - file: /etc/samba/smb.conf
    - listen_in:
      - service: service-smbd
{%   endif %}

{%   if pillar['samba']['smbldap-tools']['smbldap.conf'] is defined %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['useTLS'] is defined %}
{%       if pillar['samba']['smbldap-tools']['smbldap.conf']['useTLS'] == False %}
{%         set useTLS = 0 %}
{%       endif %}
{%     endif %}
/etc/smbldap-tools/smbldap.conf:
  file.managed:
    - name: /etc/smbldap-tools/smbldap.conf
    - source: salt://{{ os_path }}/samba/etc/smbldap-tools/smbldap.conf.jinja
    - template: jinja
    - defaults:
        sid: {{ sid }}
        sambaDomain: ''
        useTLS: 1
        verifyCert: 'require'
        users_dn: 'ou=Users'
        groups_dn: 'ou=Groups'
        computers_dn: 'ou=Computers'
        idmap_dn: 'ou=Idmap'
        login_shell: '/bin/false'
        home: '/home/%U'
        home_mode: '700'
        gecos: 'System User'
        default_gid: 513
        default_cid: 515
        maxPwAge: 45
        smbHome: ''
        smbProfile: ''
        logonScript: 'logon.bat'
        mailDomain: {{ grains['hostname'] }}
    - context:
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['SID'] is defined %}
        sid: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['SID'] }}
{%     endif %}
        sambaDomain: {{ pillar['samba']['smbldap-tools']['smbldap.conf'].get('sambaDomain', '') }}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['masterLDAP'] is defined %}
        masterLDAP: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['masterLDAP'] }}
{%     endif %}        
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['slaveLDAP'] is defined %}
        slaveLDAP: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['slaveLDAP'] }}
{%     elif pillar['samba']['smbldap-tools']['smbldap.conf']['masterLDAP'] is defined %}
        slaveLDAP: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['masterLDAP'] }}
{%     endif %}
        useTLS: {{ useTLS }}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['verifyCert'] is defined %}
        verifyCert: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['verifyCert'] }}
{%     endif %}
        base_dn: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['base_dn'] }}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['users_dn'] is defined %}
        users_dn: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['users_dn'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['groups_dn'] is defined %}
        groups_dn: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['groups_dn'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['computers_dn'] is defined %}
        computers_dn: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['computers_dn'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['idmap_dn'] is defined %}
        idmap_dn: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['idmap_dn'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['login_shell'] is defined %}
        login_shell: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['login_shell'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['home'] is defined %}
        home: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['home'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['home_mode'] is defined %}
        home_mode: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['home_mode'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['gecos'] is defined %}
        gecos: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['gecos'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['default_gid'] is defined %}
        default_gid: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['default_gid'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['default_cid'] is defined %}
        default_cid: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['default_cid'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['maxPwAge'] is defined %}
        maxPwAge: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['maxPwAge'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['smbHome'] is defined %}
        smbHome: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['smbHome'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['smbProfile'] is defined %}
        smbProfile: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['smbProfile'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['logonScript'] is defined %}
        logonScript: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['logonScript'] }}
{%     endif %}
{%     if pillar['samba']['smbldap-tools']['smbldap.conf']['mailDomain'] is defined %}
        mailDomain: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['mailDomain'] }}
{%     endif %}
    - require:
      - pkg: pkg-smbldap-tools
      - pkg: pkg-samba
    - listen_in:
      - cmd: smbldap-populate

{%     if pillar['samba']['smbldap-tools']['smbldap_bind.conf'] is defined %}
smbldap-populate:
  cmd.run:
    - name: |
        (echo {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterPW'] }}; echo {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterPW'] }}) | \
        smbldap-populate -u {{ uidstart }} -g {{ gidstart }} -r {{ midstart }}
    - unless: |
        ldapsearch -LLL -H {{ pillar['samba']['smbldap-tools']['smbldap.conf']['masterLDAP'] }} -D {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterDN'] }} -w {{ pillar['samba']['smbldap-tools']['smbldap_bind.conf']['masterPW'] }} -b {{ pillar['samba']['smbldap-tools']['smbldap.conf']['base_dn'] }} | \
        grep 'sambaDomainName: {{ pillar['samba']['smbldap-tools']['smbldap.conf']['sambaDomain'] }}'
    - require:
      - pkg: smbldap-tools
      - file: /etc/smbldap-tools/smbldap_bind.conf
      - file: /etc/smbldap-tools/smbldap.conf

{%     endif %}
{%   endif %}
{% endif %}

pkg-smbldap-tools:
  pkg.installed:
    - name: smbldap-tools
    - require:
      - pkg: pkg-samba

net-setlocalsid:
  cmd.run:
    - name: net setlocalsid {{ sid }}
    - unless: net getlocalsid | awk '/{{ sid }}/{print $6}'
    - require:
      - pkg: samba
    - listen_in:
      - service: samba-smbd

{% include os_path ~ "/etckeeper/commit.sls" %}
