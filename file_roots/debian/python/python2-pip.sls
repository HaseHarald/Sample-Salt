# python-pip - alternative Python package installer

{% set state_version = '0.0.1' %}
{% if pillar['python-pip'] is defined %}
{%   set pillar_version = pillar['python-pip'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [] %}

pkgs_python-pip:
  pkg.installed:
    - pkgs:
      - python-pip
      - python-setuptools

{% if pillar['python-pip'] is defined %}
{%   if pillar['python-pip']['install'] is defined %}
{%     for module in pillar['python-pip']['install'] %}
pip-install_{{ module }}:
  pip.installed:
    - name: {{ module }}
    - bin_env: '/usr/bin/pip2'
    - require:
      - pkg: pkgs_python-pip
{%     endfor %}
{%   endif %}
{% else %}
notification-python-pip:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

# Pillar Example
# --------------
# python-pip:
#   pillar_version: '0.0.1'
#   install:
#     - SomeProject
#     - SomeOtherProject
