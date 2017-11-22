# Manage user-accounts

{% set state_version = '0.0.2' %}
{% if pillar['users'] is defined %}
{%   set pillar_version = pillar['users'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'user: user_*'
] %}

{% if pillar['users'] is defined %}

{%   for user, args in pillar['users'].iteritems() if not user == 'pillar_version' %}
user_{{ user }}:
  user.present:
    - name: {{ user }}
{%     if 'home' in args %}
    - home: {{ args['home'] }}
{%   endif %}
{%     if 'shell' in args %}
    - shell: {{ args['shell'] }}
{%     else %}
    - shell: /bin/false
{%     endif %}
{%     if 'uid' in args %}
    - uid: {{ args['uid'] }}
{%     endif %}
{%     if 'gid' in args %}
    - gid: {{ args['gid'] }}
{%     else %}
    - gid_from_name: True
{%     endif %}
{%     if 'password' in args %}
    - password: {{ args['password'] }}
{%       if 'enforce_password' in args %}
    - enforce_password: {{ args['enforce_password'] }}
{%       endif %}
{%       if 'hash_password' in args %}
    - hash_password: {{ args['hash_password'] }}
{%       endif %}
{%     endif %}
{%     if 'fullname' in args %}
    - fullname: {{ args['fullname'] }}
{%     endif %}
{%     if 'groups' in args %}
    - groups: {{ args['groups'] }}
{%     endif %}
{%   endfor %}

{% else %}
notification-users:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

{% include "debian/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# users:
#   pillar_version: '0.0.1'
#   rms:
#     fullname: Richard Matthew Stallman
#     uid: 5000
#     gid: 5000
#     shell: /bin/bash
#     home: /home/rms
#     groups:
#       - foobar
#       - admin
#     password: TopSecret
#     hash_password: True
#     enforce_password: True
# 
#   jbond:
#     fullname: James Bond
#     shell: /bin/bash
#     home: /home/jbond
#     password: $6$SALTsalt$UiZikbV3VeeBPsg8./Q5DAfq9aj7CVZMDU6ffBiBLgUEpxv7LMXKbcZ9JSZnYDrZQftdG319XkbLVMvWcF/Vr/
#     groups:
#       - foobar
