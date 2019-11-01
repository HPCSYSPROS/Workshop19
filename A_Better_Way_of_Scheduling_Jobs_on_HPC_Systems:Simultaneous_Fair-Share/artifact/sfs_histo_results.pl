#!/usr/bin/perl

my $target_dir=$ARGV[0];
my $histo_divisor=5000;

if($target_dir eq ""){ die "first argument must be the directory where finished job files live.\n";}

open my $ls_fh,"ls $target_dir |" or die "could not open ls pipe!\n";

while(<$ls_fh>){
    if(m/(\d+)/){
	chomp;
	my $job_number=$_;
	my $job_filename=$target_dir."/".$job_number;
	open my $job_fh,"<",$job_filename or die "could not open $job_filename for reading!\n";
	
	my $username=<$job_fh>;
	chomp $username; 

	my $nodes=<$job_fh>;
	my $walltime=<$job_fh>;
	my $submittime=<$job_fh>;
	chomp $submittime;

	# what data to collect
	my $found_start=0;
	my $starttime;

	# spin through the file
	while(<$job_fh>){
	    if(m/starttime=(\d+)/){
		$found_start++;
		if($found_start > 1){ die "file $job_filename has more than one starttime!!!\n";}
		$starttime=$1;
	    }
	}

	#output the data to files
	
	#starttime data
	if(!$found_start){ 
	    print "WARNING!  file $job_filename had no starttime!!\n";
	}
	else{
	    # write out the start time value
	    my $append_command = sprintf("echo \"$username $starttime\" >> $target_dir/START_$username");
	    system($append_command);
	}

	#submit time data
	{
	    my $append_command = sprintf("echo \"$username $submittime\" >> $target_dir/SUBMIT_$username");
	    system($append_command);
	}
	close $job_fh;
    } # if(m/
} # while(<$ls_fh>)

open my $ls_start_fh,"ls $target_dir/START_* |" or die "could not open ls pipe for START files!\n";
while(<$ls_start_fh>){
    chomp;
    if(m/\/START_([A-Za-z_0-9]+)/){
	my %start_histo=();
	my $username=$1;
	my $raw_data_filename=$_;
	open my $raw_data_fh,"<",$raw_data_filename or die "could not open file $raw_data_filename to do start histogram!\n";
	while(<$raw_data_fh>){
	    chomp;
	    if(m/([A-Za-z_0-9]+) (\d+)/){
		my $temp_start_time=$2;
		my $bin_number=sprintf("%06d",int(int($temp_start_time)/int($histo_divisor)));
		my $old_bin_value=$start_histo{$bin_number};
		$start_histo{$bin_number}=$old_bin_value+1;
	    }
	}
	# now parsed whole file, write out histogram data
	close $raw_data_fh;
	my $hist_filename=$target_dir."/"."histo_start_".$username.".dat";
	open my $histo_fh,">",$hist_filename or die "could not open file $hist_filename to write start histogram\n";
	# now write sorted histogram data
	foreach my $local_key (sort(keys %start_histo)){
	    printf $histo_fh "%s %s\n",$local_key,$start_histo{$local_key};
	}
	close $histo_fh;
    }
}

open my $ls_submit_fh,"ls $target_dir/SUBMIT_* |" or die "could not open ls pipe for SUBMIT files!\n";
while(<$ls_submit_fh>){
    chomp;
    if(m/\/SUBMIT_([A-Za-z_0-9]+)/){
	my %submit_histo=();
	my $username=$1;
	my $raw_data_filename=$_;
	open my $raw_data_fh,"<",$raw_data_filename or die "could not open file $raw_data_filename to do submit histogram!\n";
	while(<$raw_data_fh>){
	    chomp;
	    if(m/([A-Za-z_0-9]+) (\d+)/){
		my $temp_start_time=$2;
		my $bin_number=int(int($temp_start_time)/int($histo_divisor));
		my $old_bin_value=$submit_histo{$bin_number};
		$submit_histo{$bin_number}=$old_bin_value+1;
	    }
	}
	# now parsed whole file, write out histogram data
	close $raw_data_fh;
	my $hist_filename=$target_dir."/"."histo_submit_".$username.".dat";
	open my $histo_fh,">",$hist_filename or die "could not open file $hist_filename to write submit histogram\n";
	# now write sorted histogram data
	foreach my $local_key (sort(keys %submit_histo)){
	    printf $histo_fh "%s %s\n",$local_key,$submit_histo{$local_key};
	}
	close $histo_fh;
    }
}

