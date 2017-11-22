# Firefox-ESR - LTS Version of the free and open source web browser from Mozilla

{% set state_version = '0.0.2' %}
{% if pillar['firefox-esr'] is defined %}
{%   set pillar_version = pillar['firefox-esr'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'pkgrepo: pkgrepo_mozillateam'
] %}

pkgrepo_mozillateam:
  pkgrepo.managed:
    - name: deb http://ppa.launchpad.net/mozillateam/ppa/ubuntu xenial main 
    - humanname: Mozilla Team - Firefox ESR and Thunderbird stable builds
    - keyid: 0AB215679C571D1C8325275B9BDB3D89CE49EC21
    - keyserver: hkp://p80.pool.sks-keyservers.net:80
    - file: /etc/apt/sources.list.d/mozilla-ppa.list
    - refresh_db: True

pkg_firefox-esr:
  pkg.installed:
    - pkgs:
      - firefox-esr
      - firefox-esr-locale-de
    - require:
      - pkgrepo: pkgrepo_mozillateam

{% include "mint_18-2/etckeeper/commit.sls" %}
