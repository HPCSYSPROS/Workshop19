#!/bin/bash

xcat_help_reset_permissions() {
	PERMISSIONS_FILE=/etc/xcat_perms
	WORK_DIR=/install/custom/commonfiles

	cd ${WORK_DIR}

	for line in `cat $PERMISSIONS_FILE | grep -v -e '^#' -e '^$'`
	do
		fname=`echo ${line} | awk -F, '(NF == 4){print $1}'`
		owner=`echo ${line} | awk -F, '(NF == 4){print $2}'`
		group=`echo ${line} | awk -F, '(NF == 4){print $3}'`
		mode=`echo ${line} | awk -F, '(NF == 4){print $4}'`

		if [[ -n "${fname}" && -n "${owner}" && -n "${group}" && -n "${mode}" && -e ${fname} ]]
		then
			chown ${owner}.${group} ${fname}
			chmod ${mode} ${fname}
		fi
	done
}
