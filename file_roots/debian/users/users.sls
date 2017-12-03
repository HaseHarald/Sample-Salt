# Manage user-accounts

{% set state_version = '0.0.4' %}
{% if pillar['users'] is defined %}
{%   set pillar_version = pillar['users'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'user: user_*'
] %}

{% if pillar['users'] is defined %}

{%   for user in pillar['users'] if not user == 'pillar_version' %}
user_{{ user }}:
  user.present:
    - name: {{ user }}
{%     if 'home' in user %}
    - home: {{ user['home'] }}
{%     endif %}
{%     if 'shell' in user %}
    - shell: {{ user['shell'] }}
{%     else %}
    - shell: /bin/false
{%     endif %}
{%     if 'uid' in user %}
    - uid: {{ user['uid'] }}
{%     endif %}
{%     if 'gid' in user %}
    - gid: {{ user['gid'] }}
{%     else %}
    - gid_from_name: True
{%     endif %}
{%     if 'password' in user %}
    - password: {{ user['password'] }}
{%       if 'enforce_password' in user %}
    - enforce_password: {{ user['enforce_password'] }}
{%       else %}
    - enforce_password: False
{%       endif %}
{%       if 'hash_password' in user %}
    - hash_password: {{ user['hash_password'] }}
{%       endif %}
{%     endif %}
{%     if 'fullname' in user %}
    - fullname: {{ user['fullname'] }}
{%     endif %}
{%     if 'groups' in user %}
    - groups: {{ user['groups'] }}
{%       if pillar['groups'] is defined %}
    - require:
{%         for group in user['groups'] if group in pillar['groups'] %}
      - group: group_{{ group }}
{%         endfor %}
{%       endif %}
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
#   rms:                                  # The user-name that is used for login
#     fullname: Richard Matthew Stallman  # [optional]
#     uid: 5000                           # [optional] defaults to system behavior
#     gid: 5000                           # [optional] defaults to setting a group that is the same as the username
#     shell: /bin/bash                    # [optional] defaults to /bin/false
#     home: /home/rms                     # [optional] defaults to system behavior
#     groups:                             # [optional] list of aditional groups to add the user to
#       - foobar
#       - admin
#     password: TopSecret                 # [optional] defaults to empty
#     hash_password: True                 # [optional] defaults to False. If False keep password as is, usefull if the password string is allready a hash.
#     enforce_password: True              # [optional] defaults to False. If True override password, even if allready set.
# 
#   jbond:
#     fullname: James Bond
#     shell: /bin/bash
#     home: /home/jbond
#     password: $6$SALTsalt$UiZikbV3VeeBPsg8./Q5DAfq9aj7CVZMDU6ffBiBLgUEpxv7LMXKbcZ9JSZnYDrZQftdG319XkbLVMvWcF/Vr/
#     groups:
#       - foobar
