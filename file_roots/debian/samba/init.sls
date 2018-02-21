# Samba - Server Message Block Protocol Server

{% set state_version = '0.0.6' %}
{% if pillar['samba'] is defined %}
{%   set pillar_version = pillar['samba'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'pkg: pkg-samba'
] %}

pkg-samba:
  pkg.installed:
    - name: samba

service-smbd:
  service.running:
    - name: smbd
    - enable: True
    - require:
      - pkg: samba
      
{% if pillar['samba'] is defined %}
include:
{%   if pillar['samba']['smb.conf'] is defined %}
  - debian.samba.smb-conf
{%	 endif %}

{%   if pillar['samba']['smbldap-tools'] is defined %}
  - debian.samba.samba-ldap
{%   endif %}

{% else %}

notification-smb-server:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% include "debian/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# # This Pillar is completely optional. However, if you decide to use certain
# # parts, you might have to get full through with it.
# samba:
#   pillar_version: '0.0.1'
#
#   # If the smb.conf-section is not set, samba will not be configured and will
#   # run as it comes from the distrebution. All direct subsections are optional
#   # aswell.
#   smb.conf:
#     # The 'global' section matches the 'global' section of the smb.conf. You
#     # can set all values in here, as you would in the smb.conf itself. Note, 
#     # that you have to use quotes it the name of the option contains spaces.
#     global: # Optional, Defaults to ... look at etc/samba/smb_global_fallback.conf.jinja
#       workgroup: 'EXAMPLE'
#       'server string': '%h server'
#       'netbios name': 'samba'
#       'wins support': 'yes'
#       'dns proxy': 'no'
#       'name resolve order': 'lmhosts host wins bcast'
#       interfaces: '127.0.0.0/8 1.2.3.4/24'
#       'bind interfaces only': 'yes'
#       'log file': '/var/log/samba/log.%I-%m-%U'
#       'log level': 1
#       'max log size': 1000
#       'panic action': '/usr/share/samba/panic-action %d'
#       security: 'user'
#       'encrypt passwords': 'true'
#       # I trust you get how to fill the rest.
#       
#     # Every other section will get its own conf file in /etc/samba/smb.conf.d/
#     # and as long it is in the pillar, it will get included in the smb.conf.
#     # Otherwise the same rules as in the global section apply.
#     demoshare: # Optional, Defaults to nothing - Can be used multiple times.
#       path: '/demo/share'
#       comment: 'Demonstrates how to set up a share'
#       available: 'yes'
#       browsable: 'yes'
#       'guest ok': 'no'
#       'writable': 'no'
#       'valid users': '@demoshare'
#       'write list': '@demoshare'
#       'create mask': '0664'
#       'directory mask': '0775'
#       'force create mode': '0660'
#       'force directory mode': '0770'
#   
#   # If you want to use LDAP for authentication with samba. You may be
#   # interested in using this part of the pillar. If set, smbldap-tools will be
#   # installed, configured and connected to the specified LDAP-Server.
#   smbldap-tools:
#     uidstart: 10000 # Optional, Defaults to 10000 - The UID to start with when adding new samba-users
#     gidstart: 10000 # Optional, Defaults to 10000 - The GID to start with when adding new groups through samba
#     midstart: 20000 # Optional, Defaults to 10000 - The MID to start with when adding new machines to samba
#     smbldap.conf:
#       SID: 'S-1-5-21-2092326337-827323919-3161327660' # Optional, Defaults to new generated SID - The SID this samba server should use
#       sambaDomain: 'sampledomain' # Optional, Defaults to empty string / whatever is configured in smb.conf - The domain name of samba
#       masterLDAP: 'ldapi:///' # Optional, Defaults to ldap://127.0.0.1 - The URL of the LDAP-master
#       slaveLDAP: 'ldap://ldap2.example.com' # Optional, Defaults to masterLDAP - The URL of the LDAP-slave if any
#       useTLS: False # Optional, Defaults to True - Whether or not to use TLS to connect to the LDAP server
#       verifyCert: 'none' # Optional, Defaults to require - How to verify the server's certificate. Possible values are none, optional and require
#       base_dn: 'dc=example,dc=com' # The base_dn of LDAP
#       users_dn: 'ou=Users' # Optional, Defaults to "ou=Users" - The Relative Distinguished Name of the users node
#       groups_dn: 'ou=Groups' # Optional, Defaults to "ou=Groups" - The RDN of the groups node
#       computers_dn: 'ou=Computers' # Optional, Default to "ou=Computers" - The RDN of the machines node
#       idmap_dn: 'ou=Idmap' # Optional, Defaults to "ou=Idmap" - The RDN for the Idmap
#       login_shell: '/bin/bash' # Optional, Defaults to /bin/false - The default login-shell for new users
#       home: '/home/%U' # Optional, Defaults to "/home/%U" where %U will be replaced with the username - The default path to the home-dir of new users
#       home_mode: '700' # Optional, Defaults to 700 - The access rights for new home-dirs. Note that you have to use quotes if you want to use the full notation, like '0750', for issues with the templating system.
#       gecos: 'System User' # Optional, Defaults to "System User" - The default gecos information for new users
#       default_gid: 65534 # Optional, Default to 65534 (nogroup) - The default main-group of new users
#       default_cid: 515 # Optional, Defaults to 515 - The default CID
#       maxPwAge: 45 # Optional, Defaults to 45 - Max password age in days
#       smbHome: '\\EXAMPLE\%U' # Optional, Defaults to empty string / "logon home" config in smb.conf - The UNC path to home drives location
#       smbProfile: '\\EXAMPLE\profiles\%U' # Optional, Defaults to empty string / "logon path" config in smb.conf - The UNC path to profiles locations
#       logonScript: '%U-logon.bat' # Optional, Defaults to 'logon.bat' - The default user netlogon script name. Make sure script file is edited under dos.
#       mailDomain: 'example.com' # Optional, Defaults to hostname of samba-server - Domain appended to the users "mail"-attribute when smbldap-useradd -M is used
#     smbldap_bind.conf:
#       masterDN: 'cn=admin,dc=example,dc=com' # The LDAP-DN used for writing access
#       masterPW: 'DemoPasswd' # The password for the masterDN
#       slaveDN: 'cn=admin,dc=example,dc=com' # Optional, Defaults to masterDN - The DN used for reading access
#       slavePW: 'DemoPasswd' # Optional, Defaults to masterPW - The password for the slaveDN

