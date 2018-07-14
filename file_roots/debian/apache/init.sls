# apache - HTTP-Server Apache

{%  set state_version = '0.1.5' %}
{%  if pillar['apache'] is defined %}
{%    set pillar_version = pillar['apache'].get('pillar_version', 'undefined') %}
{%  else %}
{%    set pillar_version = 'undefined' %}
{%  endif %}
{%  set os_path = 'debian' %}
{%  set etckeeper_watchlist = [
      'file: /etc/apache2/apache2.conf',
      'file: /etc/apache2/envvars',
      'file: /etc/apache2/ports.conf',
] %}

# Packages
pkg-apache2:
  pkg.installed:
    - name: apache2

# Service-Management
srv-apache2:
  service.running:
    - name: apache2
    - enable: True
    - require:
      - pkg: pkg-apache2
      
apache-reload:
  module.wait:
    - name: service.reload
    - m_name: apache2
    - require:
      - pkg: pkg-apache2

apache-restart:
  module.wait:
    - name: service.restart
    - m_name: apache2
    - require:
      - pkg: pkg-apache2

# Main-Configuration
/etc/apache2/apache2.conf:
  file.managed:
    - source: salt://{{ os_path }}/apache/etc/apache2/apache2.conf.jinja
    - template: jinja
    - require:
      - pkg: pkg-apache2
    - watch_in:
      - service: srv-apache2

/etc/apache2/envvars:
  file.managed:
    - source: salt://{{ os_path }}/apache/etc/apache2/envvars.jinja
    - template: jinja
    - require:
      - pkg: pkg-apache2
    - watch_in:
      - service: srv-apache2
      
/etc/apache2/ports.conf:
  file.managed:
    - source: salt://{{ os_path }}/apache/etc/apache2/ports.conf.jinja
    - template: jinja
    - require:
      - pkg: pkg-apache2
    - watch_in:
      - service: srv-apache2
 
# Modules     
{% for module in salt['pillar.get']('apache:modules:enabled', []) %}
  {% set etckeeper_watchlist = etckeeper_watchlist + [ "cmd: a2enmod-" ~ module ] %}
a2enmod-{{ module }}:
  cmd.run:
    - name: a2enmod {{ module }}
    - unless: ls /etc/apache2/mods-enabled/{{ module }}.load
    - require:
      - pkg: pkg-apache2
    - watch_in:
      - module: apache-restart
{% endfor %}

{% for module in salt['pillar.get']('apache:modules:disabled', []) %}
  {% set etckeeper_watchlist = etckeeper_watchlist + [ "cmd: a2dismod-" ~ module ] %}
a2dismod-{{ module }}:
  cmd.run:
    - name: a2dismod {{ module }}
    - onlyif: ls /etc/apache2/mods-enabled/{{ module }}.load
    - require:
      - pkg: pkg-apache2
    - watch_in:
      - module: apache-restart
{% endfor %}

# V-Hosts
{% for id, site in salt['pillar.get']('apache:sites', {}).items() %}
  {% set etckeeper_watchlist = etckeeper_watchlist + [ "file: /etc/apache2/sites-available/" ~ id ~ ".conf" ] %}
/etc/apache2/sites-available/{{ id }}.conf:
  file.managed:
    - name: /etc/apache2/sites-available/{{ id }}.conf
    - source: salt://{{ os_path }}/apache/etc/apache2/sites-available/template.conf.jinja
    - template: jinja
    - context:
        id: {{ id }}
        site: {{ site }}
    - require:
      - pkg: pkg-apache2
    - watch_in:
      - module: apache-reload

  {% if site.get('enabled', True) %}
    {% set etckeeper_watchlist = etckeeper_watchlist + [ "cmd: a2ensite-" ~ id ] %}
a2ensite-{{ id }}:
  cmd.run:
    - name: a2ensite {{ id }}.conf
    - unless: test -f /etc/apache2/sites-enabled/{{ id }}.conf
    - require:
      - file: /etc/apache2/sites-available/{{ id }}.conf
    - watch_in:
      - module: apache-reload
  {% else %}
    {% set etckeeper_watchlist = etckeeper_watchlist + [ "cmd: a2dissite-" ~ id ] %}
a2dissite-{{ id }}:
  cmd.run:
    - name: a2dissite {{ id }}.conf
    - onlyif: test -f /etc/apache2/sites-enabled/{{ id }}.conf
    - require:
      - file: /etc/apache2/sites-available/{{ id }}.conf
    - watch_in:
      - module: apache-reload
  {% endif %}

{% endfor %}

# Enable or disable default pages
manage-000-default:
  cmd.run:
{% if salt['pillar.get']('apache:enable-000-default', True) %}
    - name: a2ensite 000-default.conf
    - unless: test -f /etc/apache2/sites-enabled/000-default.conf
{% else %}
    - name: a2dissite 000-default.conf
    - onlyif: test -f /etc/apache2/sites-enabled/000-default.conf
{% endif %}
    - require:
      - pkg: pkg-apache2
    - watch_in:
      - module: apache-reload

manage-default-ssl:
  cmd.run:
{% if salt['pillar.get']('apache:enable-default-ssl', False) %}
    - name: a2ensite default-ssl.conf
    - unless: test -f /etc/apache2/sites-enabled/default-ssl.conf
{% else %}
    - name: a2dissite default-ssl.conf
    - onlyif: test -f /etc/apache2/sites-enabled/default-ssl.conf
{% endif %}
    - require:
      - pkg: pkg-apache2
    - watch_in:
      - module: apache-reload

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# apache:
#   pillar_version: 0.0.1
#   
#   apache2.conf:     # Optional - Settings of apache2.conf
#     keepalive: 'On' # Optional, Defaults to 'On'
#     log_formats:    # Optional, Defaults to the list shown here - Must be a list of strings.
#       - '"%v:%p %h %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" vhost_combined'
#       - '"%h %l %u %t \"%r\" %>s %O \"%{Referer}i\\" \"%{User-Agent}i\"" combined'
#       - '"%h %l %u %t \"%r\" %>s %O" common'
#       - '"%{Referer}i -> %U" referer'
#       - '"%{User-agent}i" agent'
#     global:         # Optional, Defaults to empty dict - Must be dict of key-value pairs. Other settings for the apache2.conf.
#       key: value
#   
#   envvars:            # Optional - Settings of envvars for apache2
#     user: 'www-data'  # Optional, Defaults to 'www-data'
#     group: 'www-data' # Optional, Defaults to 'www-data'
#     others:           # Optional Defaults to empty list - Must be list of strings. Aditional envvar settings.
#       - 'export APACHE2_MAINTSCRIPT_DEBUG=1'
#   
#   name_virtual_hosts: # Optional, Defaults to empty list - Configuration of name virtual-hosts in ports.conf. Must be List of dicts.
#     - interface: '*'  # The Interface to listen on, can also be an IP address or wildcard
#       port: 80        # The Port to listen on.
#     - interface: '*'
#       port: 443
#     
#   modules:    # Optional, Defaults to empty dict - Enable or disable several apache2 modules.
#     enabled:  # Optional, Defaults to empty list - List modules to enable
#       - ldap
#       - ssl
#     disabled: # Optional, Defaults to empty list - List modules to disable
#       - rewrite
#       
#   enable-000-default: True # Optinal, Defaults to True - Enable or disable the default page
#   enable-default-ssl: True # Optinal, Defaults to False - Enable or disable the SSL-Version of the default page
#   
#   sites:              # Optional, Defaults to empty dict - Dict of V-Hosts and their configuration. There is more things that can be configured here, take a look at etc/apache2/sites-available/template.conf.jinja
#     example.com:      # The id/name of the V-Host. Will become the filename for its configuration with an added .conf at the end. Also will become the default for some other optional values in this V-Host config.
#       enabled: True   # Optional, Defaults to True - Whether or not to enable this V-Host
#     
#     example.com-ssl:
#       enabled: True
#       port: 443                                                       # Optional, Defaults to 80 - The port to listen on 
#       ServerName: 'example.com'                                       # Optonal, Defaults to V-Host-ID - The name to listen for
#       DocumentRoot: '/var/www/example.com/'                           # Optional, Defaults to /var/www/<V-Host-ID> - The path to the document root
#       SSLCertificateFile: '/etc/ssl/certs/ssl-cert-snakeoil.pem'      # Optional, Defaults to NULL - If set, enables SSLEngine for this V-Host and sets the path to the cert file
#       SSLCertificateKeyFile: '/etc/ssl/private/ssl-cert-snakeoil.key' # Optional, Defaults to NULL - The Path to the SSL key file
# 

