# docker-ce - Linux container runtime, comunity edition

{% set state_version = '0.0.1' %}
{% if pillar['docker'] is defined %}
{%   set pillar_version = pillar['docker'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'pkgrepo: pkgrepo_docker',
  'pkg: pkg_docker-engine'
] %}

pkgs_docker_install_tools:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - ca-certificates
      - software-properties-common

pkgrepo_docker:
  pkgrepo.managed:
    - name: deb https://apt.dockerproject.org/repo ubuntu-xenial main
    - humanname: Docker Package Repository
    - keyid: 58118E89F3A912897C070ADBF76221572C52609D
    - keyserver: hkp://p80.pool.sks-keyservers.net:80
    - file: /etc/apt/sources.list.d/docker.list
    - refresh_db: True
    - require:
      - pkg: pkgs_docker_install_tools

pkg_docker-engine:
  pkg.installed:
    - name: docker-engine
    - require:
      - pkgrepo: pkgrepo_docker

{% include "mint_18-2/etckeeper/commit.sls" %}
