#!/bin/bash
# vi: set ts=2 sw=2 sts=2 et :

# Abort on failed commands
set -e

# Abort on unset variables
set -u

if [ -f "/usr/bin/dnf" ]; then
  PKGMAN="dnf"
elif [ -d "/etc/ubuntu-advantage" ]; then
  PKGMAN="apt-get"
fi

install_packages() {
  echo "Installing packages: $@"
  # This should work for at least apt/dnf
  "${PKGMAN}" install -y "$@"
}

# Some CentOS containers have firewalld which prevents access between guest OS's
if [ "$PKGMAN" == "dnf" ]; then
  systemctl stop firewalld
  systemctl disable firewalld
fi

# Ensure all nodes can log into all other nodes (create keys if not exist)
if [ ! -f /vagrant/out/id_rsa ]; then
  ssh-keygen -b 2048 -t rsa -q -N "" -f /vagrant/out/id_rsa
fi
mkdir -p /home/vagrant/.ssh
cp -p /vagrant/out/id_rsa* /home/vagrant/.ssh/
chown -R vagrant /home/vagrant/.ssh/
cat /vagrant/out/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys


# Install and configure mysql
if [ "${ENABLE_MYSQL}" == "true" ]; then
  install_packages mysql-server
  if [ "${PKGMAN}" == "apt-get" ]; then
    # Allow mysql access from more than just localhost
    sed -i 's|127.0.0.1|0.0.0.0|g' /etc/mysql/mysql.conf.d/mysqld.cnf
  fi
  systemctl enable mysql
  systemctl restart mysql
  mysql < /vagrant/provision/mysql_config_slurm_db.sql
fi

# All nodes running slurm services need munge (and slurm-client on ubuntu)
if [ "${ENABLE_SLURMD}" == "true" ] || [ "${ENABLE_SLURMCTLD}" == "true" ] || [ "${ENABLE_SLURMDBD}" == "true" ]; then
  # Create specific slurm user with the uid we're mounting its output dir as
  groupadd -g "${SLURM_GID}" slurm
  useradd -r --shell /sbin/nologin -u "${SLURM_UID}" -g "${SLURM_GID}" slurm

  rm -rfv /slurm-tmp/*
  chown -R slurm:slurm /slurm-tmp/

  # Install main slurm config
  mkdir -pv /etc/slurm/
  ln -s /vagrant/config/slurm.conf /etc/slurm/slurm.conf

  # job_submit.lua is a common script which is often used frequently
  cp /vagrant/provision/job_submit.lua /etc/slurm/job_submit.lua

  # Install optional slurm configs (if exist)
  for fname in cgroup.conf; do
    if [ -f "/vagrant/config/$fname" ]; then
      ln -sv "/vagrant/config/$fname" "/etc/slurm/$fname"
    else
      echo "No /vagrant/config/$fname detected, skipping"
    fi
  done

  # Ensure same munge key (create keys if not exist)
  install_packages munge
  if [ ! -f /vagrant/out/munge.key ]; then
    if [ -f /usr/sbin/mungekey ]; then
      sudo -u munge mungekey -f
    else
      sudo -u munge create-munge-key -f
    fi
    cp -p /etc/munge/munge.key /vagrant/out/munge.key
  else
    cp /vagrant/out/munge.key /etc/munge/munge.key
    chmod 600 /etc/munge/munge.key
    chown munge /etc/munge/munge.key
  fi
  systemctl enable munge
  systemctl restart munge

  if [ "${PKGMAN}" == "apt-get" ]; then
    install_packages slurm-client
  fi

  # This resolves openmpi issues
  install_packages libpmix-dev
fi

# slurmdbd should be installed first, since slurmctld
if [ "${ENABLE_SLURMDBD}" == "true" ]; then
  # slurmdbd.conf has pass so needs to be owned by slurm and chmod=600 (can't symlink)
  cp /vagrant/config/slurmdbd.conf /etc/slurm/slurmdbd.conf
  chown slurm:slurm /etc/slurm/slurmdbd.conf
  chmod 600 /etc/slurm/slurmdbd.conf

  if [ "${PKGMAN}" == "apt-get" ]; then
    install_packages slurmdbd
  else
    # Assume centos
    install_packages slurm slurm-{libs,slurmctld,slurmdbd}
  fi
  systemctl enable slurmdbd
  systemctl restart slurmdbd
fi

if [ "${ENABLE_SLURMCTLD}" == "true" ]; then
  mkdir -p /var/spool/slurmctld
  chown slurm:slurm /var/spool/slurmctld
  if [ "${PKGMAN}" == "apt-get" ]; then
    install_packages slurmctld
  else
    # Assume centos
    install_packages slurm slurm-{libs,slurmctld,slurmdbd}
  fi
  sleep 5  # slurmctld relies on slurmdbd, so give it a sec to startup
  systemctl enable slurmctld
  systemctl restart slurmctld
fi

if [ "${ENABLE_SLURMD}" == "true" ]; then
  mkdir -pv /var/spool/slurmd
  chown slurm:slurm /var/spool/slurmd
  if [ "$PKGMAN" == "apt-get" ]; then
    install_packages munge slurmd
  else
    # Assume centos
    install_packages slurm slurm-{libs,slurmd}
  fi
  systemctl enable slurmd
  systemctl start slurmd
fi
