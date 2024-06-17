SLURM Vagrant Cluster
=====================

A demo SLURM cluster running in Vagrant virtual machines.

# QuickStart

If you're interested in just getting an example cluster up quickly, just do:
```
$ make example1
$ vagrant plugin install vagrant-proxyconf
$ vagrant up
```

You can then ssh into the controller node with `vagrant ssh controller` and run things like `sinfo` to ensure the cluster is up:
```
$ vagrant ssh controller
vagrant@controller:~$ sinfo
```
or use the makefile shortcut:
```
$ make sinfo
```
In their case, you should see a single partition (named "normal"), and a single node (node1).
The state value should be "up". If it is "unknown", "down", or anything else, something is wrong (consult the logs).
```
$ make sinfo
vagrant ssh controller -- -t 'sinfo'
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
debug*       up   infinite      1   idle node1
```

You can now start submitting jobs to the cluster:
```
$ vagrant ssh controller
vagrant@controller:~$ srun --pty /bin/bash
vagrant@node1:~$ echo $SLURM_JOBID
1
vagrant@node1:~$ exit
exit
vagrant@controller:~$ exit
logout
$
```

The "example1" configs are setup for QoS-based preemption, and you can see this by running the `test-qos-preempt` makefile target:
```
$ make test-qos-preempt
BEGIN Testing QoS-based preemption requeue

- Starting job in low-priority QoS
Submitted batch job 3
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 3     debug  LowPrio  vagrant  R       0:06      1 node1

- Starting job in high-priority QoS
Submitted batch job 4
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 3     debug  LowPrio  vagrant PD       0:00      1 (BeginTime)
                 4     debug HighPrio  vagrant  R       0:04      1 node1

- In the above squeue output you should see:
  - The low-priority job switched to pending (PD) state
  - The high-priority job should be running (R)
- If the low-priority job is still running and the higher one pending, something is wrong

- Cleanup - Killing all jobs
END Testing QoS-based preemption requeue
```
As per the comments printed, we can see it:
1. Submitted a job on the low-priority QoS (note that squeue doesn't show qos, so you technically can't see that in the output)
2. Confirmed that said job is in `R=Running` state
3. Submitted a job on the high-priority QoS
4. Confirmed that this put the low-priority job back into `PD=Pending` state, and started running the high-priority job

NOTE: The "confirmation" is visually done by you, the code doesn't currently validate this.


# Cluster Setup

This repo will (by default) provide a cluster with 3 hosts:
1. `squid-proxy` -> A http caching proxy used to cache OS packages so that you can fully nuke/recreate the cluster quickly
2. `controller` -> Runs `slurmctld`, `slurmdbd`, and `mysql` (backing `slurmdbd`)
3. `node1` -> Runs `slurmd`

NOTE: At present, there are issues with the http proxy, so instead the pkg cache dir is shared between slurm hosts (`shared_pkgcache_dir` flag in `cluster.yaml`). This works well, but means you should only ever use the distro package manager on one host at a time.



# Usage

Before you can bring up a cluster, you need to define these 5 files:
```
config/cluster.yaml        <-- Cluster definition for VM machines
config/cgroup.conf         <-- https://slurm.schedmd.com/cgroup.conf.html
config/slurm.conf          <-- https://slurm.schedmd.com/slurm.conf.html
config/slurmdbd.conf       <-- https://slurm.schedmd.com/slurmdbd.conf.html
config/slurm_finalize.sh   <-- Final commands to run after cluster started, e.g. adding QoS/account/etc
```
Please see the examples in the `config/` dir if you want quick references.

Then you can bring the cluster up with vagrant:
```
$ vagrant up
```
and destroy it also with vagrant:
```
$ vagrant destroy -f
```

If you keep all of your settings changes stored in the 5 config files above, any time you want to test a config change, quickly destroy/recreate with:
```
$ make fresh
```

If you're making changes to slurm.conf and want to quickly reload those changes, you can use the `reload` target:
```
$ make reload
```
However note that doing this "quick" reload may not fully refresh all settings, so using `make fresh` can help in those cases.

If you want to preserve some changes you've made to the VMs you can stop them with:
```
$ make halt
```
then later start them again with:
```
$ make up
```

By default, the slurm logs are available in `out/<vm>/<service>.log`, e.g.
```
out/controller/slurmctld.log
out/controller/slurmdbd.log
out/node1/slurmd.log
```

# Different Linux Distributions & Slurm Versions

If you would like to use a different linux distro, there are a few things that you need to do
1. Set the new vagrant box via `slurm_box` variable within `config/cluster.yaml`
2. Add a `provision/set_repo.<vagrant_box_fnamestr>.sh` to setup distro repo (blank if unnecessary)
3. Modify `provision/setup_slurm.sh` as necessary (package names, etc)

If you would like to use a different slurm version, you will need to provide the install mechanism for the new version.
There isn't currently a clean path for this, but the path should look something like:
1. Create a new variable in `config/cluster.yaml` to signify the version you want
2. Add this to the `env` dict that will be passed into `provision/setup_slurm.sh`
3. Add conditional logic to `provision/setup_slurm.sh` (and potentially `provision/set_repo.<vagrant_box_fnamestr>.sh`) to handle this flag and install the alternative version

---
Fork from http://mussolblog.wordpress.com/

http://mussolblog.wordpress.com/2013/07/17/setting-up-a-testing-slurm-cluster/
