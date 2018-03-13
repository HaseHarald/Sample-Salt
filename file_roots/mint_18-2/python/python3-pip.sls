# python3-pip - alternative Python package installer
# ToDo: Rework requirements

{% set state_version = '0.0.3' %}
{% if pillar['python3-pip'] is defined %}
{%   set pillar_version = pillar['python3-pip'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set os_path = 'mint_18-2' %}
{% set etckeeper_watchlist = [
  'pip: pip3-install_*'
] %}

pkgs_python3-pip:
  pkg.installed:
    - pkgs:
      - python3-pip
      - python3-setuptools

upgrade_pip3:
  cmd.run:
    - name: '/usr/bin/pip3 install --upgrade pip'
    - user: root
    - require:
      - pkg: pkgs_python3-pip
{% if pillar['python3-pip'] is defined %}
{%   if pillar['python3-pip']['install'] is defined %}
    - prereq:
{%     for module in pillar['python3-pip']['install'] %}
      - pip: pip3-install_{{ module }}
{%     endfor %}

{%     for module in pillar['python3-pip']['install'] %}
pip3-install_{{ module }}:
  pip.installed:
    - name: {{ module }}
    - bin_env: '/usr/bin/pip3'
    - require:
      - pkg: pkgs_python3-pip
      - sls: {{ os_path }}.python.python2-pip
{%     endfor %}
{%   endif %}
{% else %}
notification-python3-pip:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# python3-pip:
#   pillar_version: '0.0.1'
#   install:
#     - SomeProject
#     - SomeOtherProject
