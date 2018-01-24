# docker-ce - Linux container runtime, comunity edition

{% set state_version = '0.0.4' %}
{% if pillar['docker'] is defined %}
{%   set pillar_version = pillar['docker'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'pkgrepo: pkgrepo_docker',
  'pkg: pkg_docker-ce',
  'cmd: cmd_get_repo_key'
] %}

pkgs_docker_install_tools:
  pkg.installed:
    - pkgs:
      - apt-transport-https
      - ca-certificates
      - software-properties-common
      - linux-headers-4.9.0-4-all
      - raspberrypi-kernel-headers
      - gnupg
      
cmd_get_repo_key:
  cmd.run:
    - name: 'curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/raspbian/gpg | apt-key add -qq -'
    - user: root
    - require:
      - sls: raspbian.base-programs.curl
    - prereq:
      - pkgrepo: pkgrepo_docker

pkgrepo_docker:
  pkgrepo.managed:
    - name: 'deb [arch=armhf] https://mirrors.aliyun.com/docker-ce/linux/raspbian {{ grains["oscodename"] }} stable'
    - humanname: Docker Package Repository
    - file: /etc/apt/sources.list.d/docker.list
    - refresh_db: True
    - require:
      - pkg: pkgs_docker_install_tools

pkg_docker-ce:
  pkg.installed:
    - name: docker-ce
    - require:
      - pkgrepo: pkgrepo_docker

{% include "raspbian/etckeeper/commit.sls" %}
