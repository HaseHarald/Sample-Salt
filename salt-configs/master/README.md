This is a somewhat basic configuration of the salt master.

Copy the files to their destination, adapt them to your needs, and uncomment the line
default_include: master.d/*.conf
in /etc/salt/master.

The Master needs the packages salt-master and python-gnupg installed. (Debian-Based)

To accept new minions use salt-key -A.
