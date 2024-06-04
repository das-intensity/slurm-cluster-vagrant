#!/bin/bash

# Abort on failed commands
set -e

# Abort on unset variables
set -u

mkdir -pv /etc/ssl/certs/
cp -v /vagrant/out/proxy/.ssl_cert/squid-self-signed.pem /etc/ssl/certs/squid-self-signed.pem

echo ""
cat /etc/apt/sources.list.d/cappelikan.list
rm -fv /etc/apt/sources.list.d/cappelikan.list
echo ""
cat /etc/apt/sources.list.d/home\:alvistack.list
rm -fv /etc/apt/sources.list.d/home\:alvistack.list
echo ""

apt-get update
