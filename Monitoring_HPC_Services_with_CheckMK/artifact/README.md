This artifact directory contains:

* HPCSYSPROS19_ArtifactDescriptor_Monitoring_EPCC.pdf
The artifact descriptor, describing the scripts and experiment workflow.

* tesseract_node_check.py

A python script developed to process the output of the "cpower" command and pass the data in an appropriate format to the Panopticon CheckMK server at EPCC. This script is run on the central management node provided with the Tesseract HPE SGI 8600 system.

* tesseract_node_check_sample_input

A sample of the node listing maintained by the HPE software stack for dsh (/etc/dsh/group/ice-compute). This is used to determine the base node list for monitoring.

* teseract_node_check_sample_output

A sample of the output of the script when run manually. This is the output for the same 12 nodes listed in the sample input.

* opa_switch_monitor.sh

This is a bash script developed to monitor the Omnipath network on the Tesseract HPE SGI 8600 system. This script is run on the "rack leader" for rack 1 of the system - this rack leader also acts as one of two fabric managers for the Omni-Path network. This script could however be run from any node from which the "opareport" command can interrogate the network. This script should be simply reproducible on any system with an Omni-Path network and CheckMK. A cron or other automatic mechanism should be used to run the script at an appropriate interval.

* opa_switch_monitor_switch.list

A sample of the switch list used to identify which switches should be monitored.

* opa_switch_monitor_output

A sample output file generated by the script.

All the source, input and output files can be found here in this git repo: https://github.com/EPCCed/hpcsystems-monitoring/
Git commit version: 60d2e3f7ede2bcbfc5be691b6bf4c6a0ef3104f7

