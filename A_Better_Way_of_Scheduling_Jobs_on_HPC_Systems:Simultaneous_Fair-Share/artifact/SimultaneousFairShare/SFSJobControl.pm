#!/usr/bin/perl
use strict;

package SimultaneousFairShare::SFSJobControl;
use base 'Exporter';
use SimultaneousFairShare::SFSUtil;
use SimultaneousFairShare::SFSLinearPriority;
use SimultaneousFairShare::SFSUpdateFunctions;
use Fcntl qw(:flock SEEK_SET);
use File::Copy qw(move);
our @EXPORT = ('sfs_start_job_running','sfs_end_job','sfs_schedule_pure_priority','sfs_prune_ended_jobs','sfs_schedule_SFS');

my $queued_dir="jobs_queued/";
my $running_dir="jobs_running/";
my $done_dir="jobs_done/";
my $job_list_by_priority="jobs_queued/priority_ordered_list";      

my %target_occ;
$target_occ{'alice'}=400;
$target_occ{'bob'}=100;
$target_occ{'chris'}=150;


sub sfs_prune_ended_jobs{
    my $global_lock=sfs_lock_exclusive_global();
    open my $ls_fh,"ls jobs_running |" or die "sfs_prune_ended_jobs: Could not open ls pipe!\n";
    my $current_time = sfs_raw_get_time();
    while(<$ls_fh>){
	chomp;
	if(m/~/){ next;}
	if(m/\./){ next;}
	if(m/[A-Za-z]/){ next;}
	# everything remaining is a job number
	my $job_name=$_;  # must do this because sub call blows away $_
	my $full_filename="jobs_running/".$job_name;
	my $job_end_time=sfs_extract_value_from_job_file($full_filename,"stoptime");
	# we have the current time and the time the job is scheduled to end
	# if we're equal to or after the scheduled end time, we end the job.
	if( int($current_time) > int($job_end_time) ){
	    print "ending job $job_name\n";
	    sfs_raw_end_job($job_name);
	}
    }
    sfs_unlock_global($global_lock);
}

sub sfs_schedule_SFS{
    my $global_lock=sfs_lock_exclusive_global();
    # schedule with the priority list as is, but gate it via Simultaneous Fairshare
    my %current_occ;
    
    # first determine initial occupancies for this time slice from already running jobs
    open my $ls_fh,"ls jobs_running |" or die "sfs_schedule_SFS: could not open ls to pipe!\n";
    print "sched_SFS: determine occupancy of already running jobs\n";
    while(<$ls_fh>){
	if(m/\d+/){
	    # it's a job
	    chomp;
	    my $job_name=$_;
	    my $job_full_name="jobs_running/$job_name";
	    open my $job_fh,"<",$job_full_name or die "sfs_schedule_SFS: could not open job_full_name for reading!\n";
	    my $username = <$job_fh>;
	    chomp $username;
	    my $node_count = <$job_fh>;
	    chomp $node_count;
	    # update occupancies
	    if($current_occ{$username}){
		# if there already is an occupancy for that user, increment it
		my $old_occ = $current_occ{$username};
		$current_occ{$username} = int($old_occ) + int($node_count);
	    }
	    else{
		$current_occ{$username}=int($node_count);
	    }
	}
    }

    # then Use those occupancies as the starting point to do simultaneous fairshare.  
    print "sched_SFS: schedule loop\n";
    open my $job_list_fh,"<",$job_list_by_priority or die "sfs_schedule_SFS: could not open priority job file!\n";
    my $launch_result=1;
    print "job list open; going through scheduling loop USING SFS!\n";
    while(<$job_list_fh>){
	if(int($launch_result) > 0){
	    if(m/(\d+) (\d+) ([A-Za-z0-9]+) (\d+)/){
		my $local_job_id=$1;
		my $local_priority=$2;
		my $local_username=$3;
		my $local_n_nodes=$4;
		if( int($current_occ{$local_username}) < int($target_occ{$local_username}) ){
		    $launch_result=sfs_start_job_running_raw($local_job_id);
		    print "considering job $local_job_id of priority $local_priority.  Result=$launch_result\n";
		    if($launch_result){
			if($current_occ{$local_username}){
			    my $old_occ = $current_occ{$local_username};
			    $current_occ{$local_username} = int($old_occ) + int($local_n_nodes);
			}
			else{
			    $current_occ{$local_username}= int($local_n_nodes);
			}
		    }
		}
	    }
	    else{
		print "WARNING: ordered priority file contains non-matching line!\n";
	    }
	}
    }
    print "exited SFS scheduling loop\n";

    # unlock and exit
    sfs_unlock_global($global_lock);
}

sub sfs_schedule_pure_priority{
    my $global_lock=sfs_lock_exclusive_global();
    open my $job_list_fh,"<",$job_list_by_priority or die "sfs_schedule_pure_priority: could not open priority job file!\n";
    my $launch_result=1;
    print "job list open; going through scheduling loop\n";
    while(<$job_list_fh>){
	if(int($launch_result) > 0){
	    if(m/(\d+) (\d+) ([A-Za-z0-9]+)/){
		my $local_job_id=$1;
		my $local_priority=$2;
	    $launch_result=sfs_start_job_running_raw($local_job_id);
		print "considering job $local_job_id of priority $local_priority.  Result=$launch_result\n";
	    }
	    else{
		print "WARNING: ordered priority file contains non-matching line!\n";
	    }
	}
    }
    print "exited scheduling loop\n";
    sfs_unlock_global($global_lock);
}

sub sfs_end_job{
    my $job_filename=$_[0];

    my $global_lock=sfs_lock_exclusive_global();
    my $return_val=sfs_raw_end_job($job_filename);
    sfs_unlock_global($global_lock);
    return $return_val;
}

sub sfs_raw_end_job{
    my $job_filename=$_[0];
    # assumes everything's locked
    my $queued_full_name=$queued_dir.$job_filename;
    my $running_full_name=$running_dir.$job_filename;
    my $done_full_name=$done_dir.$job_filename;
    
    if( -e $queued_full_name ){ die "sfs_end_job: job $queued_full_name exists in queued job directory!\n";}
    if( ! -e $running_full_name ){ die "sfs_end_job: job $running_full_name does not exist in running jobs dir!\n";}
    if( -e $done_full_name ){ die "sfs_end_job: job $done_full_name already exists in done jobs dir!\n";}
    
    # how many nodes will we free up when this job ends?
    my $occupied_nodes=sfs_raw_get_n_nodes($running_full_name);

    print "about to end job $running_full_name, it uses $occupied_nodes nodes.\n";
    sfs_raw_free_nodes_noTAS($occupied_nodes);
    rename $running_full_name,$done_full_name;

    my $actual_end_time=sfs_raw_get_time();
    sfs_append_value_to_job($done_full_name,"actual_endtime",$actual_end_time);
    
    return 1;
}

sub sfs_start_job_running{
    my $job_filename=$_[0];
    
    my $global_lock=sfs_lock_exclusive_global();
    
    my $return_result=sfs_start_job_running_raw($job_filename);
    
    sfs_unlock_global($global_lock);
    
    return $return_result;
}

sub sfs_start_job_running_raw{
    # assumes everything's locked
    my $job_filename=$_[0];

    my $queued_full_name=$queued_dir.$job_filename;
    my $running_full_name=$running_dir.$job_filename;
    my $done_full_name=$done_dir.$job_filename;
    
    if( ! -e $queued_full_name ){ die "sfs_start_job_running: job $queued_full_name does not exist!\n";}
    if( -e $running_full_name ){ die "sfs_start_job_running: job $running_full_name already exists in running jobs dir!\n";}
    if( -e $done_full_name ){ die "sfs_start_job_running: job $done_full_name already exists in done jobs dir!\n";}
    
    # check to make sure the job doesn't already have a start time
    my $job_start_time=sfs_extract_value_from_job_file($queued_full_name,"starttime");
    if($job_start_time){ die "job $job_filename already has a start time!\n";}

    my $requested_nodes=sfs_raw_get_n_nodes($queued_full_name);

    # all our checks are done; we attempt to allocated nodes for the job
    my $allocated_nodes=sfs_raw_request_commit_nodes_noTAS($requested_nodes);

    print "debug sfs_start_job_running: starting job $job_filename, allocated nodes=$allocated_nodes\n";
    
    # check to see if we secured the nodes we needed
    if( $allocated_nodes < $requested_nodes ){
	# we failed to allocate nodes for the job.  This is not necessarily 
	# an error.  There were just not enough nodes available.  
	return 0;
    }
    
    # nodes have been allocated.  Move the job to the running folder, and update counters and stuff.  

    # move job file to the running folder
    rename $queued_full_name,$running_full_name;
    
    # set the start time to the current time
    my $new_start_time=sfs_raw_get_time();
    sfs_append_value_to_job($running_full_name,"starttime",$new_start_time);
    sfs_set_binary_N($running_full_name,"eligible");
    
    return $requested_nodes;
}
