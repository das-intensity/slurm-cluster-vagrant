# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
cluster = YAML.load_file("config/cluster.yaml")
enable_proxy = cluster.key?("proxy")
if enable_proxy
  proxy = cluster["proxy"]
end

# To fetch scripts based on OS, we need a string that can be used in filenames
vagrant_box_fnamestr = cluster["slurm_box"].gsub("/", "-")

# Alpine squid seems to always have this uid/gid (in future maybe create to ensure)
squid_uid = 31
squid_gid = 31
# We create slurm with this uid/gid
slurm_uid = 444
slurm_gid = 444

append_hosts_lines = ["/bin/bash", "set -e", ""]
if enable_proxy
  append_hosts_lines.append("echo '#{proxy["ipaddress"]}  #{proxy["hostname"]}' >> /etc/hosts")
end
cluster["slurm_hosts"].values.each do |host|
  append_hosts_lines.append("echo '#{host["ipaddress"]}  #{host["hostname"]}' >> /etc/hosts")
end
append_hosts = append_hosts_lines.join("\n")

# Squid proxy to cache downloads via apt/dnf/etc
if enable_proxy
  Vagrant.configure("2") do |global_config|
    global_config.vm.define "proxy" do |config|
      config.vm.box = "generic-x64/alpine319"
      config.vm.hostname = proxy["hostname"]
      config.vm.network :private_network, ip: proxy["ipaddress"]
      config.vm.provider :virtualbox do |v|
          v.cpus = 4
          v.memory = 4096
      end

      config.vm.synced_folder ".", "/vagrant"
      config.vm.synced_folder "./out/proxy", "/squid-tmp", owner: squid_uid, group: squid_gid

      config.vm.provision :shell,
        :inline => append_hosts

      config.vm.provision :shell,
        :path => "provision/setup_squid_proxy.sh"
    end
  end
end


Vagrant.configure("2") do |global_config|
  cluster["slurm_hosts"].each_pair do |name, options|
    roles = options["roles"]
    env = {
      "ENABLE_MYSQL" => "#{roles.include? 'mysql'}",
      "ENABLE_SLURMCTLD" => "#{roles.include? 'slurmctld'}",
      "ENABLE_SLURMD" => "#{roles.include? 'slurmd'}",
      "ENABLE_SLURMDBD" => "#{roles.include? 'slurmdbd'}",
      "SLURM_UID" => "#{slurm_uid}",
      "SLURM_GID" => "#{slurm_gid}",
    }
    if enable_proxy
      env["PROXY_HOSTNAME"] = proxy["hostname"]
    end

    global_config.vm.define name do |config|
      config.vm.box = cluster["slurm_box"]
      config.vm.hostname = options["hostname"]
      config.vm.network :private_network, ip: options["ipaddress"]
      config.vm.provider :virtualbox do |v|
          v.cpus = 4
          v.memory = 4096
      end

      if enable_proxy
        # Set http proxy for apt/yum as per:
        # https://github.com/tmatilai/vagrant-proxyconf
        # Requires proxyconf plugin:
        # $ vagrant plugin install vagrant-proxyconf
        # The plugin doesn't work for dnf, so we do that manually in e.g.
        # ./provision/setup_repo.generic-x64-centos8s.sh
        config.yum_proxy.http = "http://#{proxy['hostname']}:3128"
        # TODO: Fix issue where ubuntu is sometimes insanely slow with cache, then re-enable
        # config.apt_proxy.http = "http://#{proxy['hostname']}:3128"
        # config.apt_proxy.https = "http://#{proxy['hostname']}:3128"
      end

      config.vm.synced_folder ".", "/vagrant"
      config.vm.synced_folder "./out/#{name}", "/slurm-tmp", owner: slurm_uid, group: slurm_gid

      if cluster["shared_pkgcache_dir"]
        if cluster["slurm_box"] == "alvistack/ubuntu-24.04" # apt cache dir
          config.vm.synced_folder "./out/apt-cache", "/var/cache/apt", owner: "_apt", group: "root"
        end
      end

      config.vm.provision :shell,
        :inline => append_hosts

      config.vm.provision :shell,
        :path => "provision/setup_repo.#{vagrant_box_fnamestr}.sh", :env => env

      config.vm.provision :shell, :path => "provision/setup_slurm.sh", :env => env

      # Run user-based finalize, can be used for e.g.
      # - Installing packages needed by user scripts
      # - Adding user/qos/account/etc (gate to only run one one node)
      if File.exist?("config/slurm_finalize.sh")
        config.vm.provision :shell, :path => "config/slurm_finalize.sh", :env => env
      end
    end
  end
end
