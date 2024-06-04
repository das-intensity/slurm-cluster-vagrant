#!/bin/bash

# Abort on failed commands
set -e

# Abort on unset variables
set -u

# Clean up things we don't want to carry-over
rm -rf /squid-tmp/*.log

mkdir -pv /etc/squid/ssl_cert
rm -f /etc/squid/squid.conf
ln -s /vagrant/provision/squid.conf /etc/squid/squid.conf
apk add squid

if [ ! -f /squid-tmp/.ssl_cert/squid-self-signed.pem ] || [ ! -f /squid-tmp/.ssl_db/index.txt ]; then
  # Create new self-signed cert for squid as per
  # https://rasika90.medium.com/how-i-saved-tons-of-gbs-with-https-caching-41550b4ada8a
  rm -rf /squid-tmp/.ssl_cert/* /squid-tmp/.ssl_db

  mkdir -pv /squid-tmp/.ssl_cert/
  cd /squid-tmp/.ssl_cert/
  sed -i 's|# *keyUsage = cRLSign, keyCertSign|keyUsage = cRLSign, keyCertSign|g' /etc/ssl/openssl.cnf
  openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -extensions v3_ca -keyout squid-self-signed.key -out squid-self-signed.crt -subj /
  openssl x509 -in squid-self-signed.crt -outform DER -out squid-self-signed.der
  openssl x509 -in squid-self-signed.crt -outform PEM -out squid-self-signed.pem
  openssl dhparam -outform PEM -out squid-self-signed_dhparam.pem 2048

  sudo -u squid /usr/lib/squid/security_file_certgen -c -s /squid-tmp/.ssl_db -M 20MB
fi

rc-service squid start
rc-update add squid
squid -k check
netstat -tl
