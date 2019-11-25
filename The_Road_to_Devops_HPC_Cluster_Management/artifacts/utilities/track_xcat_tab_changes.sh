#!/bin/bash

CLUSTER=cascade
REPO=git@gitlab:repo.git
BACKUP_DIR=xcatdb-cascade
BRANCH=master

REPO_BASE_DIR=/var/xcat/$CLUSTER
LOG_FILE=/var/log/track_xcat_tab_changes.log
DBBACKUPDIR=${REPO_BASE_DIR}/${BACKUP_DIR}

export PATH=$PATH:/opt/xcat/sbin:

exec >> ${LOG_FILE} 2>&1

test -d ${REPO_BASE_DIR} || mkdir -p ${REPO_BASE_DIR}
test -d ${REPO_BASE_DIR}/.git || \
	{
		git clone $REPO ${REPO_BASE_DIR}
		cd ${REPO_BASE_DIR}
		git checkout ${BRANCH}
		exit 0
	}


cd ${REPO_BASE_DIR}

git checkout ${BRANCH} >> ${LOG_FILE} 2>&1
git pull --all >> ${LOG_FILE} 2>&1

#just abort here is we dont have a valid database
if ! (/opt/xcat/bin/lsdef -t site -o clustersite -i msc_cluster_name | grep msc_cluster_name)
then
  echo No Valid database available to dump.  aborting
  exit 0
fi

/opt/xcat/sbin/dumpxCATdb -p ${DBBACKUPDIR} 2>&1 >> ${LOG_FILE}

pushd ${DBBACKUPDIR}
for file in *.csv
do
        (
        grep '^#' $file
        grep -v '^#' $file | sort
        ) > $file.new
        mv -f $file.new $file
done
popd

git commit -a --message "AUTOMATIC: Updated xcat tables."

git push 2>&1 >> ${LOG_FILE}
