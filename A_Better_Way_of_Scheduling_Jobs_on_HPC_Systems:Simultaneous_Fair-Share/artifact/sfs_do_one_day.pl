#!/usr/bin/perl

for(my $i=0;$i<24;$i++){
    print "        ---hour---\n";
    system("./sfs_do_one_hour.pl");
}
