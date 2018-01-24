# etckeeper commit - Commits changes to etckeeper

{% if etckeeper_watchlist is defined %}
etckeeper-commit-{{ sls }}:
  cmd.run:
    - user: root
    - name: etckeeper commit 'Salt commit from {{ sls }} version {{ state_version }} pillar-version {{ pillar_version }}.'
    - onchanges:
      {% for watch_element in etckeeper_watchlist %}
      - {{ watch_element }}
      {% endfor %}
    - require:
      - sls: raspbian.etckeeper.etckeeper_git
    - onlyif: etckeeper unclean
{% endif %}
