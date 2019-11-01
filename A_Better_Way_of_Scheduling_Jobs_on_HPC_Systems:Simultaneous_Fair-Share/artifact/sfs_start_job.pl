#!/usr/bin/perl
use Fcntl qw(:flock LOCK_EX LOCK_UN SEEK_END SEEK_SET);
use SimultaneousFairShare::SFSUtil;
use SimultaneousFairShare::SFSJobFunctions;
use SimultaneousFairShare::SFSUpdateFunctions;
use SimultaneousFairShare::SFSLinearPriority;
use SimultaneousFairShare::SFSJobControl;

my $job_to_start=$ARGV[0];

if(!$job_to_start){ die "you must input the job name to start!\n";}

print "we\'re going to start job $job_to_start.\n";

chomp $job_to_start;
my $job_result=sfs_start_job_running($job_to_start);

print "sfs_start_job_running returned >$job_result<.\n";
