SHELL:=/bin/bash

# slurmctld relies on slurmdbd so when they're on the same node, it fails to
# start because slurmdbd isn't up yet, so we start it again here.
up:
	vagrant up && vagrant ssh controller -- -t 'sudo systemctl restart slurmctld'

halt:
	vagrant halt

destroy:
	vagrant destroy -f

fresh: destroy up


# Reload slurm config, currently done by just restarting all services
reload:
	vagrant ssh controller -- -t 'sudo systemctl restart slurmctld'
	vagrant ssh node1 -- -t 'sudo systemctl restart slurmd'

sinfo:
	vagrant ssh controller -- -t 'sinfo'

squeue:
	vagrant ssh controller -- -t 'watch -n 1 squeue --me'

sacct:
	vagrant ssh controller -- -t 'sacct'

example1:
	ln -sfn slurm.conf.example1 config/slurm.conf
	ln -sfn slurmdbd.conf.example1 config/slurmdbd.conf
	ln -sfn cgroup.conf.example1 config/cgroup.conf
	ln -sfn slurm_finalize.sh.example1 config/slurm_finalize.sh

# This test will:
# 1. Launch a job in the "low" qos
# 2. Launch a job in the "high" qos
# Since both jobs use the entire CPU count from node1 (the only node), the 2nd job should preempt the first
test-qos-preempt:
	@echo "BEGIN Testing QoS-based preemption requeue"
	@echo ""
	@echo "- Starting job in low-priority QoS"
	@vagrant ssh controller -- -t 'sbatch --qos=low --cpus-per-task=4 --mem=256 --requeue --wrap="srun sleep 300" --job-name LowPrio'
	@sleep 5
	@vagrant ssh controller -- -t 'squeue --me'
	@echo ""
	@echo "- Starting job in high-priority QoS"
	@vagrant ssh controller -- -t 'sbatch --qos=high --cpus-per-task=4 --mem=256 --requeue --wrap="srun sleep 300" --job-name HighPrio'
	@sleep 5
	@vagrant ssh controller -- -t 'squeue --me'
	@echo ""
	@echo "- In the above squeue output you should see:"
	@echo "  - The low-priority job switched to pending (PD) state"
	@echo "  - The high-priority job should be running (R)"
	@echo "- If the low-priority job is still running and the higher one pending, something is wrong"
	@sleep 3
	@echo ""
	@echo "- Cleanup - Killing all jobs"
	@vagrant ssh controller -- -t 'scancel -u vagrant'
	@echo "END Testing QoS-based preemption requeue"
