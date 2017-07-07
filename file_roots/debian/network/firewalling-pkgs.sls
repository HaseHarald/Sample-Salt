# iptables and netfilter - packages required for propper firewalling

# Install required packages for firewalling      
iptables.pkgs:
  pkg.installed:
    - pkgs:
      - iptables
      - iptables-persistent

netfilter-persistent.pkg:
  pkg.installed:
    - name: netfilter-persistent
    - require:
      - pkg: iptables.pkgs

