#!/usr/bin/lua

-- This script implements Slurm's 'job_submit' interface.
-- It will be call on all job submissions.
--
-- This blocks job submissions with more than MAX_JOB_ARGS arguments
-- Currently (as of Slurm 19.05.5), the argc is only populated for
-- sbatch jobs; salloc and srun set argc to 0, regardless of the
-- number of arguments.
--
-- This script was added following an outage (T68819939) that was
-- caused by having too many arguments passed into a sbatch.
-- To prevent this, this script will reject any sbatch job with
-- more than MAX_JOB_ARGS. The value for MAX_JOB_ARGS was set to
-- 256 somewhat arbitrarily, as a "reasonable" limit between 0
-- and 8600 (the number of arguments that caused the outage).
--
-- If users complain that 256 is too low, we should increment to
-- the next power of two until we find the limit.
--
-- Log statements go into the slurmctld.log
-- Logs will show the user that submitted the job, and the number
-- of arguments in their job submission.

MAX_JOB_ARGS = 256

function slurm_job_submit(job_desc, part_list, submit_uid)
    if job_desc.argc > MAX_JOB_ARGS then
        slurm.log_info("slurm_job_submit blocked job submit from user (%u) (too many args -> %d)", submit_uid, job_desc.argc)
        return slurm.ERROR
    end

    return slurm.SUCCESS
end

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
    if job_desc.argc > MAX_JOB_ARGS then
        slurm.log_info("slurm_job_modify blocked job update from user (%u) (too many args -> %d)", submit_uid, job_desc.argc)
        return slurm.ERROR
    end

    return slurm.SUCCESS
end

slurm.log_info("job_submit.lua initialized")
return slurm.SUCCESS
