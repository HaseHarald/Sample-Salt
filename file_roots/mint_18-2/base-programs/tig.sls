# tig - text-mode interface for Git

pkg-tig:
  pkg.installed:
    - name: tig
  require:
    - sls: mint_18-2.base-programms.git
