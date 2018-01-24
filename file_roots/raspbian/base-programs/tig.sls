# tig - text-mode interface for Git

pkg-tig:
  pkg.installed:
    - name: tig
  require:
    - sls: raspbian.base-programms.git
