This is a somewhat basic configuration of the salt minion.

Copy the files to their destination, adapt them to your needs, and uncomment the line
default_include: minion.d/*.conf
in /etc/salt/minion.

The Minion needs the packages salt-minion and python-gnupg installed. (Debian-Based)
