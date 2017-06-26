# tig - text-mode interface for Git

pkg-tig:
  pkg.installed:
    - name: tig
  require:
    - sls: debian.base-programms.git
