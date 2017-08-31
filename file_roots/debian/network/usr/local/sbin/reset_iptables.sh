#!/bin/bash

# ==========================================
# This file is managed by Salt. Do not edit!
# ==========================================

# Reset policys
/sbin/iptables -t filter -P INPUT ACCEPT
/sbin/iptables -t filter -P OUTPUT ACCEPT
/sbin/iptables -t filter -P FORWARD ACCEPT

# Flush chains
/sbin/iptables -t filter -F

# Delete user defined chains
/sbin/iptables -t filter -X
