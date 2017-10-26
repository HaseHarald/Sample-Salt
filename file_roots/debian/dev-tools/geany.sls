# geany - fast and lightweight IDE

{% set state_version = '0.0.1' %}
{% if pillar['geany'] is defined %}
{%   set pillar_version = pillar['geany'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [] %}

pkgs_geany:
  pkg.installed:
    - pkgs:
      - geany
      - geany-plugins
      - geany-plugin-addons
      - geany-plugin-vc
      - geany-plugin-git-changebar


