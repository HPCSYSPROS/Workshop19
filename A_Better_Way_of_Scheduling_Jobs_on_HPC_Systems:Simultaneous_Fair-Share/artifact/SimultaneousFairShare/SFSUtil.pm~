#!/usr/bin/perl
use strict;
use Fcntl qw(:flock);

package SimultaneousFairShare::SFSUtil;
use base 'Exporter';
use Fcntl qw(:flock SEEK_SET);
our @EXPORT = ('sfs_lock_jobs_queued','sfs_unlock_jobs_queued','sfs_lock_jobs_running','sfs_lock_jobs_done','sfs_lock_sfs_core','sfs_lock_exclusive_global','sfs_lock_shared_global','sfs_unlock_jobs_running','sfs_unlock_jobs_done','sfs_unlock_sfs_core','sfs_unlock_global','sfs_get_time','sfs_increment_time_by','sfs_raw_get_time','sfs_raw_request_commit_nodes_noTAS','sfs_raw_get_n_nodes','sfs_raw_free_nodes_noTAS','sfs_raw_get_username');

# initializations here
#$sfs_global_lock_file="./lock"

sub sfs_lock_jobs_queued{
    return sfs_sub_lock_EX("./jobs_queued/lock");
}

sub sfs_lock_jobs_running{
    return sfs_sub_lock_EX("./jobs_running/lock");
}

sub sfs_lock_jobs_done{
    return sfs_sub_lock_EX("./jobs_done/lock");
}

sub sfs_lock_sfs_core{
    return sfs_sub_lock_EX("./sfs_core/lock");
}

sub sfs_lock_exclusive_global{
    return sfs_sub_lock_EX("./lock");
}

sub sfs_lock_shared_global{
    return sfs_sub_lock_SH("./lock");
}

sub sfs_unlock_jobs_queued{
    return sfs_sub_unlock($_[0]);
}
sub sfs_unlock_jobs_running{
    return sfs_sub_unlock($_[0]);
}
sub sfs_unlock_jobs_done{
    return sfs_sub_unlock($_[0]);
}
sub sfs_unlock_sfs_core{
    return sfs_sub_unlock($_[0]);
}

sub sfs_unlock_global{
    return sfs_sub_unlock($_[0]);
}

sub sfs_sub_lock_EX{
    my $lock_file_name=$_[0];
    open my $lock_fh,">>",$lock_file_name or die "could not open $lock_file_name!";
    flock($lock_fh,LOCK_EX) or die "could not lock file $lock_file_name!";
    return $lock_fh;
}

sub sfs_sub_lock_SH{
    my $lock_file_name=$_[0];
    open my $lock_fh,">>",$lock_file_name or die "could not open $lock_file_name!";
    flock($lock_fh,LOCK_SH) or die "could not lock file $lock_file_name!";
    return $lock_fh;
}

#sub sfs_global_lock{
#    my $lock_file_name=$sfs_global_lock_file;
#    open my $lock_fh,">>",$lock_file_name or die "could not open $lock_file_name!";
#    flock($lock_fh,LOCK_EX) or die "could not lock file $lock_file_name!";
#    return $lock_fh;
#}

sub sfs_sub_unlock{
    flock($_[0],LOCK_UN) or die "could not unlock file!";
    close($_[0]) or die "could not close lock file!";
    return 0;
}

sub sfs_get_time{
    my $global_lock=sfs_lock_shared_global();
    my $my_lock=sfs_lock_sfs_core();
    my $current_time=sfs_raw_get_time();
    sfs_unlock_sfs_core($my_lock);
    sfs_unlock_global($global_lock);
    return $current_time;
}

sub sfs_raw_get_time{
    open my $time_fh,"<","./sfs_core/current_time" or die "sfs_get_time could not open time file!\n";
    my $current_time=<$time_fh>;
    chomp $current_time;
    return $current_time;
}

sub sfs_increment_time_by{
    my $time_delta=$_[0];
    my $global_lock=sfs_lock_exclusive_global();

    open my $time_fh,"+<","./sfs_core/current_time" or die "sfs_increment_time_by could not open time file!\n";
    my $current_time=<$time_fh>;
    seek $time_fh,0,SEEK_SET;
    my $new_time = int($current_time)+int($time_delta);
    my $new_time_str = sprintf("%09d\n",$new_time);
    print $time_fh "$new_time_str\n";
    
    sfs_unlock_global($global_lock);
    return $new_time_str;
}

sub sfs_raw_get_username{
    # assumes everything's locked
    my $job_filename=$_[0];
    open my $job_fh,"<",$job_filename or die "sfs_raw_get_n_nodes: could not open job file $job_filename for reading!\n";
    my $username=<$job_fh>;
    close $job_fh;
    chomp $username;
    return $username;
}

sub sfs_raw_get_n_nodes{
    # assumes everything's locked
    my $job_filename=$_[0];
    open my $job_fh,"<",$job_filename or die "sfs_raw_get_n_nodes: could not open job file $job_filename for reading!\n";
    my $username=<$job_fh>;
    my $n_nodes=<$job_fh>;
    close $job_fh;
    chomp $n_nodes;
    return $n_nodes;    
}

sub sfs_raw_free_nodes_noTAS{
    my $n_nodes=$_[0];

    # get currently occupied nodes
    open my $occupied_fh,"+<","./sfs_core/number_of_nodes_occupied" or die "sfs_raw_request_commit_nodes: can\'t open occupied nodes file!\n";
    my $current_occupied=<$occupied_fh>;
    chomp $current_occupied;

    if( $current_occupied < $n_nodes ){ die "sfs_raw_free_nodes_noTAS: requested to free $n_nodes nodes, but only $current_occupied are occupied!\n";}

    seek $occupied_fh,0,SEEK_SET;
    my $new_occupied_nodes = int ( $current_occupied - $n_nodes );
    chomp $new_occupied_nodes;
    printf $occupied_fh "%08d\n",$new_occupied_nodes;
    close $occupied_fh;
    return (-($n_nodes));
}

sub sfs_raw_request_commit_nodes_noTAS{
    my $requested_nodes=$_[0];
    chomp $requested_nodes;
    # assume we already have a global lock
    
    # get total nodes
    open my $total_nodes_fh,"<","./sfs_core/number_of_nodes" or die "sfs_raw_request_commit_nodes: can\'t open total nodes file!\n";
    my $total_nodes=<$total_nodes_fh>;
    close $total_nodes_fh;
    chomp $total_nodes;

    # get currently occupied nodes
    open my $occupied_fh,"+<","./sfs_core/number_of_nodes_occupied" or die "sfs_raw_request_commit_nodes: can\'t open occupied nodes file!\n";
    my $current_occupied=<$occupied_fh>;
    chomp $current_occupied;

    # calculate available nodes
    my $available_nodes = int ( $total_nodes - $current_occupied );
    print "sfs_raw_request_commit_nodes_noTAS: total=$total_nodes, occ=$current_occupied, avail=$available_nodes\n";
    if( int($available_nodes) < int($requested_nodes) ){
	# wasn't able to reserve nodes; indicate failure (but not necessarily error)
	close $occupied_fh;
	return 0;	
    }
    else{
	seek $occupied_fh,0,SEEK_SET;
	my $new_occupied_nodes = int ( $current_occupied + $requested_nodes );
	chomp $new_occupied_nodes;
	printf $occupied_fh "%08d\n",$new_occupied_nodes;
	close $occupied_fh;
	return $requested_nodes;
    }
}

1;
