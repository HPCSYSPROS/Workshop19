#!/bin/bash

exec >> /var/log/xcat-git-update.log 2>&1

umask 0022

cd /install/cluster

if [[ ! -d .git ]]
then
	git clone git@gitlab .
fi
git add -A
git stash
git clean -f -d
git pull
git checkout master 2>&1
  ./show_vers_log.sh > custom/postscripts/version.txt
  cd custom
git reset --hard origin/master
  . /usr/local/sbin/xcat_misc_helpers.sh
  xcat_help_reset_permissions
