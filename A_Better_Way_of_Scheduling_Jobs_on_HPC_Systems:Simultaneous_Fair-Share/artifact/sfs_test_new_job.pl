#!/usr/bin/perl
#use lib '/home/craig/work/sfs/sfs_core';
#use Fcntl qw(:flock SEEK_END);
use Fcntl qw(:flock LOCK_EX LOCK_UN SEEK_END SEEK_SET);
use SimultaneousFairShare::SFSUtil;
use SimultaneousFairShare::SFSJobFunctions;

sfs_add_new_job($ARGV[0],$ARGV[1],@ARGV[2]);

