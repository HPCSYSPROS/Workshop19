#!/usr/bin/perl

my $vertical_margin=25;
my %file_list;
my %start_time_list;

open my $ls_fh,"ls |" or die "could not open ls!!\n";

while(<$ls_fh>){
    # for every file in the dir
    chomp;
    if(m/(\d\d\d\d\d\d\d\d\d)/){
#     print "job filename: $_\n";
	$job_filename=$_;
	open my $job_fh,"<",$job_filename or die "could not open job filename $job_filename for reading in first loop!\n";
	# now we have the individual job filename open; parse the file
	$user=<$job_fh>;
	chomp $user;
	my $nodes=<$job_fh>;
	chomp $nodes;
	<$job_fh>; # requested walltime
	my $request_time=<$job_fh>;
	chomp $request_time;
	my $start_time=-1;
	my $end_time=-1;
	while(<$job_fh>){
	    chomp;
	    if(m/starttime=(\d+)/){ $start_time=$1; chomp $start_time; }
	    if(m/actual_endtime=(\d+)/){ $end_time=$1; chomp $start_time; }
	}
	close $job_fh;
	$file_list{$start_time}=$job_filename;
	$start_time_list{$job_filename}=$start_time;
    }
} # while(<$ls_fh>)
close($ls_fh);

print ("import matplotlib.pyplot as plt\n");

my $original_vertical_baseA=0;
#my $original_vertical_baseB=2000;
#my $original_vertical_baseC=4000;
my $original_vertical_baseB=0;
my $original_vertical_baseC=0;



my $vertical_baseA=$original_vertical_baseA;
my $vertical_baseB=$original_vertical_baseB;
my $vertical_baseC=$original_vertical_baseC;
my $count=1;
print STDERR "about to run second loop!\n";


# foreach my $start_time (sort keys %file_list){
#foreach my $my_job_filename (sort values %start_time_list){
foreach my $my_job_filename (sort { $start_time_list{$a} <=> $start_time_list{$b} } keys %start_time_list){




#    print STDERR "second loop iteration key=$my_job_filename\n";

#    $myfilename=$file_list{$start_time};
    $myfilename=$my_job_filename;
    

    open my $job_fh,"<",$myfilename or die "could not open job filename $myfilename for reading in second loop!\n";
    # now we have the individual job filename open; parse the file
    $user=<$job_fh>;
    chomp $user;
    my $nodes=<$job_fh>;
    chomp $nodes;
    <$job_fh>; # requested walltime
    my $request_time=<$job_fh>;
    chomp $request_time;
    my $start_time=-1;
    my $end_time=-1;
    while(<$job_fh>){
	chomp;
	if(m/starttime=(\d+)/){ $start_time=$1; chomp $start_time; }
	if(m/actual_endtime=(\d+)/){ $end_time=$1; chomp $start_time; }
    }
    
    # print "job $job_filename; nodes=$nodes, request=$request_time, start=$start_time, end=$end_time\n";
    if($user eq "alice") { 
	my $bottom=$vertical_baseA;
	my $top=$vertical_baseA+$nodes;
	my $left=sprintf("%d",$start_time);
	my $right=sprintf("%d",$end_time);
	my $xname="x$count";
	my $yname="y$count";
	# starts in lower left goes clockwise
	print "y$count=[$bottom,$top,$top,$bottom]\n";
	print "x$count=[$left,$left,$right,$right]\n";
	print "plt.fill($xname,$yname,'b')\n"; 
	$vertical_baseA = $top + $vertical_margin;
	my $left=sprintf("%d",$request_time);
	my $right=sprintf("%d",$request_time+($nodes*10));
	print "y$count=[$bottom,$top,$top,$bottom]\n";
	print "x$count=[$left,$left,$right,$right]\n";
	print "plt.fill($xname,$yname,'b')\n"; 
	$vertical_baseA = $top + $vertical_margin;
#	if( ($vertical_baseA - $original_vertical_baseA) > 1500) { $vertical_baseA = $original_vertical_baseA; }
    } 
    if($user eq "bob") { 
	my $bottom=$vertical_baseB;
	my $top=$vertical_baseB+$nodes;
	my $left=sprintf("%d",$start_time);
	my $right=sprintf("%d",$end_time);
	my $xname="x$count";
	my $yname="y$count";
	# starts in lower left goes clockwise
	print "y$count=[$bottom,$top,$top,$bottom]\n";
	print "x$count=[$left,$left,$right,$right]\n";
	print "plt.fill($xname,$yname,'r')\n"; 
	$vertical_baseB = $top + $vertical_margin;
#	if( ($vertical_baseB - $original_vertical_baseB) > 1500) { $vertical_baseB = $original_vertical_baseB; }	
    } 
    if($user eq "chris") { 
	my $bottom=$vertical_baseC;
	my $top=$vertical_baseC+$nodes;
	my $left=sprintf("%d",$start_time);
	my $right=sprintf("%d",$end_time);
	my $xname="x$count";
	my $yname="y$count";
	# starts in lower left goes clockwise
	print "y$count=[$bottom,$top,$top,$bottom]\n";
	print "x$count=[$left,$left,$right,$right]\n";
	print "plt.fill($xname,$yname,'y')\n"; 
	$vertical_baseC = $top + $vertical_margin;	
#	if( ($vertical_baseC - $original_vertical_baseC) > 1500) { $vertical_baseC = $original_vertical_baseC; }
    } 
    
    $count++;
#    $vertical_base = $top + $vertical_margin;
    close($job_fh);
}
