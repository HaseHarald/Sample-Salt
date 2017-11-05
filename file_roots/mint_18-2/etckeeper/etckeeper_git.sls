# etckeeper - store /etc in git, mercurial, bazaar, or darcs

{% set state_version = '0.0.2' %}
{% if pillar['etckeeper'] is defined %}
{%   set pillar_version = pillar['etckeeper'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/etckeeper/etckeeper.conf'
] %}

pkg-etckeeper-git:
  pkg.installed:
    - name: etckeeper
    - require:
      - sls: mint_18-2.base-programs.git

/etc/etckeeper/etckeeper.conf:
   file.replace:
   - name: /etc/etckeeper/etckeeper.conf
   - pattern: '^VCS="(.*)"$'
   - repl: 'VCS="git"'
   - not_found_content: 'VCS="git"'
   - append_if_not_found: True
   - require:
      - pkg: pkg-etckeeper-git

etckeeper-init:
  cmd.run:
    - cwd: /etc
    - name: etckeeper init
    - unless: test -d /etc/.git
    - require:
      - file: /etc/etckeeper/etckeeper.conf

/etc/.git/config:
  file.append:
    - name: /etc/.git/config
    - text: |
        [user]
           email = root@localhost
           name = root
    - require:
      - cmd: etckeeper-init
      
etckeeper_commit_at_start:
  cmd.run:
    - order: 0
    - cwd: /etc
    - name: '/usr/bin/etckeeper commit "Changes found prior to start of salt run #salt-start"'
    - onlyif: 'test -d /etc/.git && test -n "$(git status --porcelain)"'

etckeeper_commit_at_end:
  cmd.run:
    - order: last
    - cwd: /etc
    - name: '/usr/bin/etckeeper commit "Changes made during salt run #salt-end"'
    - onlyif: 'test -d /etc/.git && test -n "$(git status --porcelain)"'
    

