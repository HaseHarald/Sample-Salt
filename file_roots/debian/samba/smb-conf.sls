# smb.conf - Configure samba-server

{% set state_version = '0.0.5' %}
{% if pillar['samba'] is defined %}
{%   set pillar_version = pillar['samba'].get('pillar_version', 'undefined') %}
{% else %}
{%   set pillar_version = 'undefined' %}
{% endif %}
{% set etckeeper_watchlist = [
  'file: /etc/samba/smb.conf',
  'file: /etc/samba/smb.conf.d/',
  'file: /etc/samba/smb.conf.d/*'
] %}

/etc/samba/smb.conf:
  file.managed:
    - name: /etc/samba/smb.conf
    - template: jinja
{% if 'global' not in pillar['samba']['smb.conf'] %}
    - source: salt://debian/samba/etc/samba/smb_global_fallback.conf.jinja
    - require:
      - pkg: pkg-samba
      - file: /etc/samba/smb.conf.d/
{% else %}
    - source: salt://debian/samba/etc/samba/smb.conf.jinja
    - require:
      - pkg: pkg-samba
      - file: /etc/samba/smb.conf.d/
{%   for section in pillar['samba']['smb.conf'] if not section == 'global' %}
      - file: /etc/samba/smb.conf.d/{{ section }}.conf
{%   endfor %}
{% endif %}
    - listen_in:
      - service: service-smbd

{% for section in pillar['samba']['smb.conf'] if not section == 'global' %}
/etc/samba/smb.conf.d/{{ section }}.conf:
  file.managed:
    - name: /etc/samba/smb.conf.d/{{ section }}.conf
    - source: salt://debian/samba/etc/samba/smb.conf.d/template.conf.jinja
    - template: jinja
    - listen_in:
      - service: service-smbd
    - context:
      section: {{ section }}
    - require:
      - file: /etc/samba/smb.conf.d/
{% endfor %}

/etc/samba/smb.conf.d/:
  file.directory:
    - name: /etc/samba/smb.conf.d
    - user: root
    - group: root
    - filemode: 644
    - dirmode: 755
    - makedirs: True
    - recurse:
      - user
      - group
      - mode
    - require: 
      - pkg: pkg-samba

{% include "debian/etckeeper/commit.sls" %}
