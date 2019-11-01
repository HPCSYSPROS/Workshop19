#!/usr/bin/perl
use Fcntl qw(:flock LOCK_EX LOCK_UN SEEK_END SEEK_SET);
use SimultaneousFairShare::SFSUtil;
use SimultaneousFairShare::SFSJobFunctions;
use SimultaneousFairShare::SFSUpdateFunctions;
use SimultaneousFairShare::SFSLinearPriority;
use SimultaneousFairShare::SFSJobControl;
# time increment for testing = 5 minutes or 300 seconds.
my $time_increment=300;

# first increment the current time
sfs_increment_time_by($time_increment);

# then run all of the update/cleanup processes that need to be done
# each time step
sfs_update_all_job_counters();
sfs_set_linear_priorities();
sfs_assemble_prioritized_job_list();
sfs_ensure_end_values_for_running();
sfs_prune_ended_jobs();

print "about to sched SFS\n";
sfs_schedule_SFS();
print "finished schedule SFS\n";
sfs_set_linear_priorities();
sfs_assemble_prioritized_job_list();

# choose which scheduler to use here
sfs_schedule_pure_priority();
#sfs_schedule_SFS();

print "time slice update finished.\n";
