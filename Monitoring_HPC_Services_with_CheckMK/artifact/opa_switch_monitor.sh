#!/bin/bash --login

###############################################################################
#
# This script monitors the state of the Omnipath network on Tesseract output
# is formatted and directed for integration into CheckMK monitoring system. 
# Where links disappear CheckMK will alert.
#
#
# Authors:  Kieran Leach
#           HPC Systems team, EPCC, University of Edinburgh
#
#           2019-08-01
#
# MIT License
#
###############################################################################

# Define temp directory for generating output files
destdir="/root/switch_monitoring/switch_links"
timevalid="900"
last=""
lastid=""

switchname=""

# Operate over set of switches defined 
for switch in $(cat /root/switch_monitoring/switch.list)
do

total=0
swtotal=0

echo "<<<<tssw-$switch>>>>" > $destdir/$timevalid$switch
echo "<<<local>>>" >> $destdir/$timevalid$switch

# Operate over data provided by opareport for each switch defined in 
# switch.list
# opareport data provided pairs of lines defining connections.
# 1. Paired lines are identified by shared link IDs.
# 2. Node description is checked against the the name of the switch in question 
# to determine which of the pair is the switch being checked.
# 3. If the interface which does not represent the switch being checked is of 
# the type SW relevant data is added to the output and the total number of 
# connections is incremented.

for line in $(opareport -o links -x -F node:"$switch" 2>&1 | opaxmlextract -H -e Link:id -e PortNum -e NodeType -e NodeDesc | grep -v "^;")
do
	# Parse opareport line for relevant details
	id=$(echo $line | awk -F ";" '{print $1}')
	nodedesc=$(echo $line | awk -F ";" '{print $4}')
	portnum=$(echo $line | awk -F ";" '{print $2}')
	ctype=$(echo $line | awk -F ";" '{print $3}')

	# (1)
	if [ "$id" == "$lastid" ]
	then
		# (2)
		if [ "$nodedesc" == "$switch" ]
		then
			let total++
			# (3)
			echo "0 $portnum:$(echo $lastnodedesc | tr ' ' '_') - $id, $lastctype" | grep "SW" >> $destdir/$timevalid$switch
			if [ "$lastctype" == "SW" ]
			then
				let swtotal++
			fi
		# (2)
		elif [ "$lastnodedesc" == "$switch" ]
		then
			let total++
			# (3)
                        echo "0 $lastportnum:$(echo $nodedesc | tr ' ' '_') - $id, $ctype"| grep "SW" >> $destdir/$timevalid$switch
                        if [ "$ctype" == "SW" ]
                        then
                                let swtotal++
                        fi
		fi



	fi

	last=$line
	lastid=$id
	lastnodedesc=$nodedesc
	lastportnum=$portnum
	lastctype=$ctype
done

# Append output listing total links and total inter-switch links.
echo "0 total_links links=$total links=$total" >> $destdir/$timevalid$switch
echo "0 inter_switch_links links=$swtotal links=$swtotal" >> $destdir/$timevalid$switch

#Check for outputs on the switch in question and append data.
errors="$(opareport -o slowlinks -F node:$switch -x 2>&1 | opaxmlextract -H -e LinksWithErrors)"
if [ "$errors" == "0" ]
then
    echo "0 link_errors errors=$errors errors=$errors" >> $destdir/$timevalid$switch
else
    echo "2 link_errors errors=$errors errors=$errors" >> $destdir/$timevalid$switch
fi
echo "<<<<>>>>" >> $destdir/$timevalid$switch
done

#Simultaneously copy monitoring output for all switches to the spool directory
mv -f $destdir/* /var/lib/check_mk_agent/spool/
