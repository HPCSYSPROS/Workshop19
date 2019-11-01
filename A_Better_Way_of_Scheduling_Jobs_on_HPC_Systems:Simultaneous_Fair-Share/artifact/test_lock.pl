#!/usr/bin/perl
#use lib '/home/craig/work/sfs/sfs_core';
#use Fcntl qw(:flock SEEK_END);
use Fcntl qw(:flock LOCK_EX LOCK_UN SEEK_END SEEK_SET);
use SimultaneousFairShare::SFSUtil;
use SimultaneousFairShare::SFSJobFunctions;

print "\nlock test script beginning\n\n";
$wait_in_sec = $ARGV[0];
$my_ID = $ARGV[1];
if($wait_in_sec == 0){ die "first argument must be a wait value!\n";}
if(! $my_ID){ die "second argument must be our ID!\n";}
print "wait value is: $wait_in_sec, my ID is $my_ID\n";
print "\n";

for(my $i=0; $i<5; $i++){
    print "$my_ID about to lock.\n";
    my $handle=sfs_lock_jobs_queued();
    print "$my_ID locked, about to wait.\n";
    sleep $wait_in_sec;
    print "$my_ID wait finished, about to unlock.\n";
    sfs_unlock_jobs_queued($handle);
    close $handle;
    print "$my_ID unlocked, end of loop.\n";
    my $current_time=sfs_get_time();
    print "time=$current_time\n";
    sfs_increment_time_by(7);
    sfs_add_new_job("bob",8);
}

