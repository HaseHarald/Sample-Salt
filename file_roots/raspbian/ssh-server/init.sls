# OpenSSH - OpenBSD Secure Shell server

{% set state_version = '0.0.2' %}
{% if pillar['openssh'] is defined %}
{%   set pillar_version = pillar['openssh'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/ssh/sshd_config'
] %}

pkg-openssh-server:
  pkg.installed:
    - name: openssh-server

service-openssh-server:    
  service.running:
    - name: ssh
    - enable: True
    - watch:
      - file: /etc/ssh/sshd_config
    - require:
      - pkg: pkg-openssh-server

{% if pillar['openssh'] is defined %}

{%   if pillar['openssh']['sshd_config'] is defined %}
/etc/ssh/sshd_config:
  file.managed:
    - name: /etc/ssh/sshd_config
    - source: salt://raspbian/ssh-server/etc/ssh/sshd_config.jinja
    - template: jinja
    - require:
      - pkg: pkg-openssh-server
{%   endif %}

{%   if pillar['openssh'].get('ssh_auth') %}
{%     for user in pillar['openssh']['ssh_auth']['user'] %}
{%       for comment in pillar['openssh']['ssh_auth']['user'][user] %}
ssh_auth-{{ user }}-{{ comment }}:
  ssh_auth.present:
    - user: {{ user }}
    - name: {{ pillar['openssh']['ssh_auth']['user'][user][comment]['key'] }}
    - enc: {{ pillar['openssh']['ssh_auth']['user'][user][comment]['enc'] }}
    - comment: {{ comment }}
    - config: {{ pillar['openssh']['ssh_auth'].get('config', '.ssh/authorized_keys') }}
{%         if pillar['users'] is defined %}
{%           if user in pillar['users'] %}
    - require:
      - user: user_{{ user }}
{%           endif %}
{%         endif %}
{%       endfor %}
{%     endfor %}
{%   endif %}

{% else %}
notification-ssh-server:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% include "raspbian/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# openssh:
#   pillar_version: '0.0.1'
#   sshd_config:
#     ports:
#       - 22
#       - 22222
#     listen_addresses:
#       - 127.0.0.1
#       - ::1
#       - 12.34.56.78
#     address_family: 'any'
#     permit_root_login: 'prohibit-password'
#     pubkey_authentication: 'yes'
#     password_authentication: 'yes'
#     use_PAM: 'yes'
#     x11_forwarding: 'yes'
#   ssh_auth:
#     user:
#       USERNAME:
#         USER@HOST:
#           key: 'PUBLIC-KEY-HERE'
#           enc: 'ssh-rsa'
