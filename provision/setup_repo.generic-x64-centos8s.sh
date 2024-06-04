#!/bin/bash

# Abort on failed commands
set -e

mkdir -pv /etc/ssl/certs/
cp -v /vagrant/out/proxy/.ssl_cert/squid-self-signed.pem /etc/ssl/certs/squid-self-signed.pem

# Regular repos
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
# epel repos
# - The epel repos would work without this, but they'd often choose different mirror, so caching proxy doesn't work
sed -i -E 's|^(#)?baseurl=https://download.example/pub/epel|baseurl=http://epel.mirror.constant.com|g' /etc/yum.repos.d/epel*.repo
sed -i 's/^metalink/#metalink/g' /etc/yum.repos.d/epel*.repo
# Hyperscale
dnf install -y centos-release-hyperscale
dnf config-manager --set-enabled powertools
sed -i -E 's|^(#)?baseurl=http://mirror.centos.org|baseurl=https://unicom.mirrors.ustc.edu.cn/centos-vault|g' /etc/yum.repos.d/CentOS-Stream-Hyperscale.repo
sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Stream-Hyperscale.repo

if [ -z "$PROXY_HOSTNAME}" ]; then
    # Enable squid proxy via proxy/sslcacert vars as per
    # https://dnf.readthedocs.io/en/latest/conf_ref.html
    echo "proxy=http://${PROXY_HOSTNAME}:3128" >> /etc/dnf/dnf.conf
    echo "sslcacert=/etc/ssl/certs/squid-self-signed.pem" >> /etc/dnf/dnf.conf
    # TODO once we fix the issuer name on the cert, we shouldn't need this
    echo "sslverify=0" >> /etc/dnf/dnf.conf
fi
