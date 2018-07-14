# makes sure a given directory is present

{% set state_version = '0.0.5' %}
{% set pillar_version = salt['pillar.get']('mkdir:pillar_version', 'undefined') %}
{% set os_path = 'raspbian' %}
{% set etckeeper_watchlist = [
  'file: mkdir-*'
] %}

{% for path, options in salt['pillar.get']('mkdir', {}).items() if not path == "pillar_version" %}
  {% set require_group = False %}
  {% set require_user = False %}
  {% if options['group'] is defined %}
    {% if options['group'] in salt['pillar.get']('groups', {}) %}
      {% set require_group = True %}
    {% endif %}
  {% endif %}
  {% if options['user'] is defined %}
    {% if options['user'] in salt['pillar.get']('users', {}) %}
      {% set require_user = True %}
    {% endif %}
  {% endif %}
mkdir-{{ path }}:
  file.directory:
    - name: {{ path }}
  {% if options['user'] is defined %}
    - user: {{ options['user'] }}
  {% endif %}
  {% if options['group'] is defined %}
    - group: {{ options['group'] }}
  {% endif %}
  {% if options['mode'] is defined %}
    - mode: {{ options['mode'] }}
  {% endif %}
    - makedirs: {{ options.get('makedirs', True) }}
  {% if require_group or require_user %}
    - require:
    {% if require_group %}
      - group: group_{{ options['group'] }}
    {% endif %}
    {% if require_user %}
      - user: user_{{ options['user'] }}
    {% endif %}
  {% endif %}
{% endfor %}

{% if pillar['mkdir'] is not defined %}
notification-mkdir:
  test.show_notification:
    - text: {{ 'You can define pillar data for this state, for more informations read the example comment for this state in %s.' % sls }}
{% endif %}

{% include os_path ~ "/etckeeper/commit.sls" %}

# Pillar Example
# --------------
# mkdir:
#   pillar_version: '0.0.1'
#   /some/path:     # The path of the directory this is all about
#     user: foo     # Optional, defaults to system settings - The user this directory belongs to
#     group: bar    # Optional, defaults to system settings - The group this directory belongs to
#     mode: '2775'  # Optional, defaults to system settings - The access mode this directory has
#     makedirs: True  # Optional, defaults to True - Whether or not to create the directory, if it doesn't exist
#   /some/different/path: {}



