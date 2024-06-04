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

You can then ssh into the controller node with `vagrant ssh controller` and run things like `sinfo`:
```
TODO
```

# Cluster Setup

This repo will (by default) provide a cluster with 3 hosts:
1. `squid-proxy` -> A http caching proxy used to cache OS packages so that you can fully nuke/recreate the cluster quickly
2. `controller` -> Runs `slurmctld`, `slurmdbd`, and `mysql` (backing `slurmdbd`)
3. `node1` -> Runs `slurmd`




# Usage

Build VM's

```
make setup
```

Start SLURM daemons inside VM's

```
make start
```
Test that it is working

```
make test
```

## Extras

Stop VM's that are running

```
make stop
```
(must be restarted with `vagrant up`, or by running `make setup` again)

Delete VM's

```
make remove
```

Clean out SLURM logs

```
make clean
```

# Software

Tested with:

- Vagrant 2.4.1

- SLURM 15.08.7 (Ubuntu 16.04)

---
Fork from http://mussolblog.wordpress.com/

http://mussolblog.wordpress.com/2013/07/17/setting-up-a-testing-slurm-cluster/
