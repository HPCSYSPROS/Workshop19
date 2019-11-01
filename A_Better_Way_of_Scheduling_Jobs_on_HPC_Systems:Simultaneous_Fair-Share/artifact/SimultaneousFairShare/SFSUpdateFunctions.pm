#!/usr/bin/perl
use strict;

package SimultaneousFairShare::SFSUpdateFunctions;
use base 'Exporter';
use SimultaneousFairShare::SFSUtil;
use Fcntl qw(:flock SEEK_SET);
use File::Copy qw(move);
our @EXPORT = ('sfs_update_queued_job_counters','sfs_set_binary_state','sfs_set_binary_N','sfs_raw_update_job_counters_dir','sfs_update_all_job_counters');

# function that updates the counters in each job in some directory

sub sfs_set_binary_N{
    my $job_filename=$_[0];
    my $state_to_change=$_[1];
    
    if($job_filename eq ""){ die "sfs_set_binary_N: first argument job filename must not be empty!\n";}
    if($state_to_change eq ""){ die "sfs_set_binary_N: second argument, state name, must not be empty!\n";}
    return sfs_set_binary_state($job_filename,$state_to_change,"N");
}

sub sfs_set_binary_state{
    # assumes locking is done
    my $old_job_filename=$_[0];
    my $state_name=$_[1];
    my $new_state=$_[2];
    
    if($old_job_filename eq ""){ die "sfs_set_binary_state: first argument must be job file to set state in!\n";}
    my $new_job_filename=$old_job_filename."_new";

    if($state_name eq ""){ die "sfs_set_binary_state: second argument must be the name of the tag to change state of!\n";}

    if($new_state ne "Y" && $new_state ne "N"){ die "sfs_set_binary_state: third argument must be Y or N!\n";}
    
    open my $old_job_fh,"<",$old_job_filename or die "sfs_set_binary_state: could not open file $old_job_filename for reading to update!\n";
    open my $new_job_fh,">",$new_job_filename or die "sfs_set_binary_state: could not open file $new_job_filename to update!\n";
    
    my $we_have_found_tag=0;
    while(<$old_job_fh>){
	if(m/([A-Za-z0-9_]+)=([YN]) (\d+)/){
	    my $this_line_tag=$1;
	    my $old_state=$2;
	    my $counter=$3;

	    if($this_line_tag eq $state_name){
		# we've found the tag line we need to change!
		$we_have_found_tag++;
		if($we_have_found_tag > 1){ die "sfs_set_binary_state: file $old_job_fh had MULTIPLE >$this_line_tag< tags!\n";}
		if($new_state eq $old_state){ print "WARNING: new state being applied is already the state!  State:$new_state, file:$old_job_filename\n";}
		printf $new_job_fh "%s=%s %s\n",$this_line_tag,$new_state,$counter;
	    }
	    else{
		# it's a binary tag line but not the one we're looking for
		# so just print it back out to the output file.
		print $new_job_fh $_;
	    }
	}
	else{
	    # it doesn't match the binary pattern, just spit the line out 
	    print $new_job_fh $_;
	}
    }
    close $old_job_fh;
    close $new_job_fh;

    if($we_have_found_tag){
	# we did a replacement; need to swap in new file for old
	unlink $old_job_filename;
	rename $new_job_filename,$old_job_filename;
	return 1;
    }
    else{
	# we didn't find the tag; just remove the new file and leave the old one alone.
	unlink $new_job_filename;
	return 0;
    }    
}

sub sfs_update_all_job_counters{
    my $global_lock=sfs_lock_exclusive_global();

    my $my_directory="jobs_queued";
    sfs_raw_update_job_counters_dir($my_directory);

    my $my_directory="jobs_running";
    sfs_raw_update_job_counters_dir($my_directory);

    my $my_directory="jobs_done";
    sfs_raw_update_job_counters_dir($my_directory);

    sfs_unlock_global($global_lock);
}

sub sfs_raw_update_job_counters_dir{
    my $dir=$_[0];
    open my $my_ls_fh,"ls $dir|" or die "sfs_raw_update_job_counters_dir: could not open ls pipe!\n";
    while(<$my_ls_fh>){
	chomp;
#	print "checking file: >$_<\n";
	if(m/new/){
	    print "WARNING!  We ran across a stale _new file!  $_\n";
	    next;
	}
	# silently skip over any files with "~" in them just in case I had a modified 
	# test file
	if(m/~/){
#	    print "skipping because of \"~\"\n";
	    next;
	}
	if(m/(\d+)/){
	    
	    # any filename in that directory that has any digits in it is a job name
	    # so we perform our update on it
	    my $raw_job_name = $1;
#	    print "raw_job_name=>$raw_job_name<\n";
	    my $full_job_name = $dir."/".$raw_job_name;
#	    print "about to call sfs_update_job_counters on >$full_job_name<\n";
	    sfs_update_job_counters($full_job_name);
	}
    }
    
}

sub sfs_update_job_counters{
    # we assume this function is entered with everything already in a LOCKED state
    # so no locking to be done
    # we assume the calling function has locked everything and is calling this function
    # on each relevant job

    # this function creates a new file to write the output to, with "_new" appended to the filename.  It writes out the new file
    # as it parses the old file.  Then it closes both files, removes the original file, and mv's the new file back to the 
    # old file's name.
    my $job_filename=$_[0];
#    print "about to update $job_filename\n";
    my $new_job_filename=$job_filename."_new";
    open my $old_job_fh, "<",$job_filename or die "sfs_update_job_counters: could not open file $job_filename for reading!\n";
    open my $new_job_fh, ">",$new_job_filename or die "sfs_update_job_counters: could not open file new file $job_filename for updating!\n";

    
    # we need to parse down the header to get the "last time updated" file name.  
    my $username=<$old_job_fh>;
    my $n_nodes=<$old_job_fh>;
    my $requested_time=<$old_job_fh>;
    my $time_job_created=<$old_job_fh>;
    my $last_time_job_updated=<$old_job_fh>;
    
    # now we have the job information; we need to find out what time it is.
    my $current_time=sfs_raw_get_time();
    my $elapsed_time = $current_time - $last_time_job_updated;
    if($elapsed_time < 0){
	die "sfs_update_job_counters WARNING: job $job_filename elapsed time is $elapsed_time which is less than zero!\n";
    }
    if($elapsed_time > 3600){
	print "WARNING: sfs_update_job_counters WARNING: job $job_filename elapsed time is $elapsed_time which is suspiciously high!\n";
    }

    # parsed the file header.  Now we use seek to back up to the beginning of the input file.
    seek $old_job_fh,0,SEEK_SET;

    # now we parse through the first four lines of the old file, line, by line, and write the same lines to the output file.
    my $header_line=<$old_job_fh>;
    print $new_job_fh $header_line;
    my $header_line=<$old_job_fh>;
    print $new_job_fh $header_line;
    my $header_line=<$old_job_fh>;
    print $new_job_fh $header_line;
    my $header_line=<$old_job_fh>;
    print $new_job_fh $header_line;

    # this read is just to position the read pointer past this line.  
    my $old_last_time_job_updated=<$old_job_fh>;
    # the fifth line is the last-update-time which we set to NOW
    printf $new_job_fh "%09d\n",$current_time;
    
    # now go through the lines after the header and update the ones that need it
    while(my $wholeline=<$old_job_fh>){
	if($wholeline =~ m/\A([A-Za-z_]+)=(Y|N) (\d+)/){
	    # if this is a timeer that perhaps we need to update, first we'll parse the line to find out the 
	    # state (yes/no) and the total logged time.  Then update the logged time if necessary.  After that, 
	    # we re-write the updated line.
	    my $state_name=$1;
	    my $yes_no=$2;
	    my $current_counter=$3;
#	    print "state line parsing: [$state_name] [$yes_no] [$current_counter]\n";
	    my $updated_counter;
	    if($yes_no eq "Y"){
		# the timer says "Y" (the state IS current in force) so we update the elapsed timer
		$updated_counter=$current_counter+$elapsed_time;
#		print "counter is Y, >$current_counter< >$updated_counter<\n";
	    }
	    else{
		$updated_counter=$current_counter;
#		print "counter is N\n";
	    }	    
#	    print "debug: $state_name, $yes_no, $updated_counter\n";
	    printf $new_job_fh "%s=%s %09d\n",$state_name,$yes_no,$updated_counter;
	} 
	elsif($wholeline =~ m/\A([A-Za-z_]+)=([0-9A-Za-z_\/\.]+)/){
	    # nothing to update here, but this is a legal line, we just print it to the output
	    # file verbatim
	    print $new_job_fh $wholeline;
	}
	else{
	    # according to the format, this is not a legal line
	    # we'll print it to the output file, but warn.  
	    print $new_job_fh $wholeline;
	    print "WARNING!  Job file >$job_filename< contains line >>>$wholeline<<< which is illegal!\n";
	}
    }
    close $old_job_fh;
    close $new_job_fh;
    
    unlink $job_filename;
    rename $new_job_filename,$job_filename;
}
