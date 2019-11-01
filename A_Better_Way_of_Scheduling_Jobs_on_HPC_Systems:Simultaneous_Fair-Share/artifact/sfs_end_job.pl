#!/usr/bin/perl
use Fcntl qw(:flock LOCK_EX LOCK_UN SEEK_END SEEK_SET);
use SimultaneousFairShare::SFSUtil;
use SimultaneousFairShare::SFSJobFunctions;
use SimultaneousFairShare::SFSUpdateFunctions;
use SimultaneousFairShare::SFSLinearPriority;
use SimultaneousFairShare::SFSJobControl;

my $job_to_end=$ARGV[0];

if(!$job_to_end){ die "you must input the job name to end!\n";}

print "we\'re going to end job $job_to_end.\n";

chomp $job_to_end;
my $job_result=sfs_end_job($job_to_end);

print "sfs_end_job returned >$job_result<.\n";
