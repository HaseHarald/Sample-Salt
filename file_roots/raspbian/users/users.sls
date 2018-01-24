# Manage user-accounts

{% set state_version = '0.0.6' %}
{% if pillar['users'] is defined %}
{%   set pillar_version = pillar['users'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'raspbian' %}
{% set etckeeper_watchlist = [
  'user: user_*'
] %}

{% if pillar['users'] is defined %}

{%   for user in pillar['users'] if not user == 'pillar_version' %}
{%     set args = pillar['users'][user] %}
user_{{ user }}:
  user.present:
    - name: {{ user }}
{%     if args['home'] is defined %}
    - home: {{ args['home'] }}
{%     endif %}
{%     if args['shell'] is defined %}
    - shell: {{ args['shell'] }}
{%     else %}
    - shell: /bin/false
{%     endif %}
{%     if args['uid'] is defined %}
    - uid: {{ args['uid'] }}
{%     endif %}
{%     if args['gid'] is defined %}
    - gid: {{ args['gid'] }}
{%     else %}
    - gid_from_name: True
{%     endif %}
{%     if args['password'] is defined %}
    - password: {{ args['password'] }}
{%       if args['enforce_password'] is defined %}
    - enforce_password: {{ args['enforce_password'] }}
{%       else %}
    - enforce_password: False
{%       endif %}
{%       if args['hash_password'] is defined %}
    - hash_password: {{ args['hash_password'] }}
{%       endif %}
{%     endif %}
{%     if args['fullname'] is defined %}
    - fullname: {{ args['fullname'] }}
{%     endif %}
{%     if args['groups'] is defined %}
    - groups: {{ args['groups'] }}
{%       if pillar['groups'] is defined %}
    - require:
{%         for group in args['groups'] if group in pillar['groups'] %}
      - group: group_{{ group }}
{%         endfor %}
{%       endif %}
{%     endif %}
{%   endfor %}

{%   include os_path ~ "/etckeeper/commit.sls" %}

{% else %}
notification-users:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}

{% endif %}

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
#     password: TopSecret                 # [optional] defaults to empty. Use 'mkpasswd -m sha-512 -S saltsalt -s' to generate a passwordhash on the commandline.
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
