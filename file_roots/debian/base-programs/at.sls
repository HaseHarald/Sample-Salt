# at - Execute commands at later time

pkg-at:
  pkg.installed:
    - name: at
  service.running:
    - name: atd
    - enable: True

