#!/bin/bash

# Abort on failed commands
set -e

mkdir -pv /etc/ssl/certs/
cp -v /vagrant/out/proxy/.ssl_cert/squid-self-signed.pem /etc/ssl/certs/squid-self-signed.pem

if [ -z "$PROXY_HOSTNAME}" ]; then
    # Enable squid proxy via proxy/sslcacert vars as per
    # https://dnf.readthedocs.io/en/latest/conf_ref.html
    echo "proxy=http://${PROXY_HOSTNAME}:3128" >> /etc/dnf/dnf.conf
    echo "sslcacert=/etc/ssl/certs/squid-self-signed.pem" >> /etc/dnf/dnf.conf
    # TODO once we fix the issuer name on the cert, we shouldn't need this
    echo "sslverify=0" >> /etc/dnf/dnf.conf
fi
