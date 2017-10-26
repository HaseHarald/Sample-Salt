# dia - a diagram drawing program

pkgs_dia:
  pkg.installed:
    - pkgs:
      - dia
      - dia-shapes

pkg_dia2code:
  pkg.installed:
    - sources:
      - dia2code: 'salt://dibian/dev-tools/pkgs/dia2code_0.8.8-1~lookbehind1_amd64.deb'
