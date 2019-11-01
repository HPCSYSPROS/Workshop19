#!/usr/bin/perl
use strict;

package SimultaneousFairShare::SFSLinearPriority;
use base 'Exporter';
use SimultaneousFairShare::SFSUtil;
use Fcntl qw(:flock SEEK_SET);
use File::Copy qw(move);
our @EXPORT = ('sfs_set_linear_priorities','sfs_assemble_prioritized_job_list','sfs_ensure_end_values_for_running','sfs_extract_value_from_job_file','sfs_append_value_to_job');

#scheduling_weight_constants
# first line is for node-count dominant priority
# second line is for eligible-time dominant priority
#my $sfs_weight_nodes=741;
my $sfs_weight_nodes=247;
my $sfs_weight_eligible_seconds=1;

my $sfs_priority_order_filename="jobs_queued/priority_ordered_list";

sub sfs_ensure_end_values_for_running{
    my $dir="jobs_running";
    my $global_lock=sfs_lock_exclusive_global();
    my @dirlist=sfs_list_of_jobs_in_directory($dir);
    foreach my $job_name (@dirlist){
	my $full_name = $dir."/".$job_name;
	my $sample_val=sfs_extract_value_from_job_file($full_name,"planned_stoptime");
	if(!$sample_val){
	    # if it does NOT have a value, we'll give it one.
	    sfs_set_end_value_one_job($full_name);
	}
    }
    sfs_unlock_global($global_lock);
}

sub sfs_set_end_value_one_job{
    # assumes everything's locked
    my $job_filename=$_[0];
    my $walltime=sfs_requested_walltime_from_job($job_filename);
    if(!$walltime) { die "sfs_set_end_value_one_job: job >$job_filename< has no requested walltime!\n"; }
    my $stoptime_value=sfs_extract_value_from_job_file($job_filename,"stoptime");
    if($stoptime_value){ return; }
    my $job_start_time=sfs_extract_value_from_job_file($job_filename,"starttime");
    if(!$job_start_time) { die "sfs_set_end_value_one_job: job $job_filename has no starttime!\n";}
    my $calculated_stoptime = int($job_start_time + int( ($walltime*(0.7)) + ($walltime*rand()*(0.2))));

    print "current: $job_start_time walltime=$walltime  stop time=>>>$calculated_stoptime<<<\n";
    if(sfs_append_value_to_job($job_filename,"stoptime",$calculated_stoptime)){
	print "assign stoptime: yay success!\n";
    }
    else{
	print "failed to assign stoptime.\n";
    }
}

sub sfs_append_value_to_job{
    # assumes everything's locked
    my $my_jobfilename=$_[0];
    my $new_key=$_[1];
    my $new_value=$_[2];
    open my $my_fh,"+<",$my_jobfilename or die "sfs_append_value_to_job: could not open >$my_jobfilename< for read/update!";
    while(<$my_fh>){
	if(m/\A([A-Za-z_]+)=([0-9A-Za-z_\/\.]+)/){
	    if($1 eq $new_key){
		# oops, we're trying to append a value that's already there!
		close $my_fh;
		return 0;
	    }
	}
    }
    # now off the end of the file, didn't find an already existing value.
    printf $my_fh "%s=%s\n",$new_key,$new_value;
    close $my_fh;
    return 1;
}

sub sfs_requested_walltime_from_job{
    #assumes everything's locked
    my $my_jobfilename=$_[0];
    open my $my_fh,"<",$my_jobfilename or die "sfs_extract_value_from_job_file: could not open >$my_jobfilename< for reading!";
    my $throwaway=<$my_fh>; # read past username
    $throwaway=<$my_fh>; # read past n nodes
    my $requested_walltime=<$my_fh>;
    chomp $requested_walltime;
    return $requested_walltime;
}

sub sfs_extract_value_from_job_file{
    # assumes everything's locked
    my $my_jobfilename=$_[0];
    my $search_key=$_[1];
    open my $my_fh,"<",$my_jobfilename or die "sfs_extract_value_from_job_file: could not open >$my_jobfilename< for reading!";
    while(<$my_fh>){
	if(m/\A([A-Za-z_]+)=([0-9A-Za-z_\/\.]+)/){
	    if($1 eq $search_key){
		my $return_value=$2;
		chomp $return_value;
		close $my_fh;
		return $return_value;
	    }
	}
    }
    close $my_fh;
    return "";
}

sub sfs_list_of_jobs_in_directory{
    # assumes locking
    my @job_list=();
    my $dir=$_[0];
    open my $my_ls_fh,"ls $dir|" or die "sfs_list_of_jobs_in_directory: could not open ls pipe!\n";
    while(<$my_ls_fh>){
	chomp;
	if(m/(\d+)/ && ! m/~/){
	    push @job_list,$_;
	}
    }
    return @job_list;
}

sub sfs_assemble_prioritized_job_list{
    # context here is that we're making a sorted listed of *queued* jobs
    # for use in scheduling decisions
    my %job_priority_list=();
    my $global_lock=sfs_lock_exclusive_global();
    my $dir="jobs_queued";
    open my $order_file_fh,">",$sfs_priority_order_filename or die "could not open $sfs_priority_order_filename!\n";
    open my $my_ls_fh,"ls $dir|" or die "sfs_assemble_prioritized_job_list: could not open ls pipe!\n";
    while(<$my_ls_fh>){
	chomp;	
# 	print "next ls value: $_\n";
	if(m/(\d+)/ && ! m/~/){
	    my $this_job_name=$_; # doing this because sub call resets the value of $_
	    my $full_file_name=$dir."/".$this_job_name;
	    my $priority_value=sfs_extract_value_from_job_file($full_file_name,"priority");	    
# 	    print "find priorty from file [$full_file_name] {$this_job_name} = $priority_value\n";
	    $job_priority_list{$this_job_name}=$priority_value;
	}
    }
    close $my_ls_fh;
    # the job_priority_list is loaded.  Now put the sorted list into a file
    foreach my $job_num (sort {$job_priority_list{$b} <=> $job_priority_list{$a}} keys %job_priority_list){
	# grab the username so we can use that in priority determination
	my $full_filename = $dir."/".$job_num;
	my $username = sfs_raw_get_username($full_filename);
	my $nodes = sfs_raw_get_n_nodes($full_filename);
	printf $order_file_fh "%s %s %s %s\n",$job_num,$job_priority_list{$job_num},$username,$nodes;
    }
    close $order_file_fh;
    sfs_unlock_global($global_lock);    
}

sub sfs_set_linear_priorities{
    my $global_lock=sfs_lock_exclusive_global();
    my $dir="jobs_queued";
    open my $my_ls_fh,"ls $dir|" or die "sfs_set_linear_priorities: could not open ls pipe!\n";
    while(<$my_ls_fh>){
	chomp;
#	print "checking file: $_\n";
	if(m/new/){
	    print "WARNING!  We ran across a stale _new file!  $_\n";
	    next;
	}
	# skip the odd stray job file that I've edited in emacs, producing a backup.
	if(m/~/){
	    next;
	}
	if(m/(\d+)/){
	    
	    # any filename in that directory that has any digits in it is a job name
	    # so we perform our update on it
	    my $raw_job_name = $1;
	    my $full_job_name = $dir."/".$raw_job_name;
	    sfs_set_one_linear_priority($full_job_name);
	}
    }
    
    sfs_unlock_global($global_lock);
}

sub sfs_set_one_linear_priority{
    # we assume this function is entered with everything already in a LOCKED state
    # so no locking to be done
    # we assume the calling function has locked everything and is calling this function
    # on each relevant job

    my $job_filename=$_[0];
#    print "about to update $job_filename\n";
    my $new_job_filename=$job_filename."_new";
    open my $old_job_fh, "<",$job_filename or die "sfs_set_one_linear_priority: could not open file $job_filename for reading!\n";
    open my $new_job_fh, ">",$new_job_filename or die "sfs_set_one_linear_priority: could not open file new file $job_filename for updating!\n";

    # now we parse through the first four lines of the old file, line, by line, and write the same lines to the output file.
    my $header_line=<$old_job_fh>;
    print $new_job_fh $header_line;

    my $header_line=<$old_job_fh>;
    print $new_job_fh $header_line;
    my $num_nodes_requested=$header_line;
    chomp $num_nodes_requested;

    my $header_line=<$old_job_fh>;
    print $new_job_fh $header_line;

    my $header_line=<$old_job_fh>;
    print $new_job_fh $header_line;
    
    # parse through the lines looking for what we need for priority
    my $found_priority_entry=0;
    my $found_eligible_time=0;
    my $eligible_time_result;
    my $output_priority;
    while(<$old_job_fh>){
	if(m/eligible=[YN] (\d+)/){
	    $found_eligible_time++;
	    if($found_eligible_time > 1){ die "file >$job_filename< has more than one eligible counter!\n";}
	    $eligible_time_result=$1;
	    $output_priority = 
		( $eligible_time_result * $sfs_weight_eligible_seconds) + 
		( $num_nodes_requested * $sfs_weight_nodes );
	    print $new_job_fh $_;
	}
	elsif(m/priority=(\d+)/){
	    $found_priority_entry++;
	    if($found_priority_entry > 1){ die "file >$job_filename< has more than one priority entry!\n";}
	    if( ! $found_eligible_time ){ die "on priority line; no eligible time tag found!\n";}
	    
	    printf $new_job_fh "priority=%09d\n",$output_priority;
	}
	else{
	    print $new_job_fh $_;
	}
    }
    if($found_priority_entry < 1){
	if($found_eligible_time > 0){
	    # We did get the eligible time, so we can calculate priority
	    # but we didn't see the priority entry, so we'll write it here.
	    printf $new_job_fh "priority=%09d\n",$output_priority;
	}
	else{
	    die "file >$job_filename< doesn't have an eligible time entry!\n";
	}
    }
    # now do priority calculation
    
    close $old_job_fh;
    close $new_job_fh;
    
    unlink $job_filename;
    rename $new_job_filename,$job_filename;
}
