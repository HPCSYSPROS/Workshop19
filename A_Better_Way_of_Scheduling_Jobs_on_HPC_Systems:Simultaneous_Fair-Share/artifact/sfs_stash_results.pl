#!/usr/bin/perl

# find non-existent results directory
my $directory_found=0;
my $i=0;
my $dirname;
while( ! $directory_found && $i<100000 ){
    $dirname=sprintf("results_%06d",$i);
    if( ! -e $dirname ){
	mkdir $dirname;
	$directory_found=1;
    }
    $i++;
}


open my $fh_ls,"ls jobs_done |" or die "Could not open ls command!\n";
while(<$fh_ls>){
    chomp;
    print "about to match $_\n";
    if(m/(\d+)/){
	my $orig_filename="jobs_done/".$_;
	my $dest_filename=$dirname."/".$_;
	print "matched. moving $orig_filename to $dest_filename\n";
	rename $orig_filename,$dest_filename;
    }
}
