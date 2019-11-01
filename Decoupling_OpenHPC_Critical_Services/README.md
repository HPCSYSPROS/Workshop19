# Decoupling OpenHPC Critical Services

**Authors:**
* Jacob Chapell, University of Kentucky
* Bhushan Chitre, University of Kentucky
* Vikram Gazula, University of Kentucky
* Lowell Pike, University of Kentucky
* James Griffoen, University of Kentucky

**Abstract:**
High-Performance Computing (HPC) cluster-management software often consolidates cluster-management functionality into a centralized management node, using it to provision the compute nodes, manage users, and schedule jobs. A consequence of this design is that the management node must typically be up and operating correctly for the cluster to schedule and continue executing jobs. This dependency de-incentivizes administrators from upgrading the management node because the entire cluster may need to be taken down during the upgrade. Administrators may even avoid performing minor updates to the management node for fear that an update error could bring the cluster down.
To address this problem, we redesigned the structure of management nodes, specifically OpenHPC’s System Management Server (SMS), breaking it into components that allow portions of the SMS to be taken down and upgraded without interrupting the rest of the cluster. Our approach separates the time-critical SMS tasks from tasks that can be delayed, allowing us to keep a relatively small number of time-critical tasks running while bringing down critical portions of the SMS for long periods of time to apply OpenHPC upgrades, update applications, and perform acceptance tests on the new system.
We implemented and deployed our solution on the University of Kentucky’s HPC cluster, and it has already helped avoid downtime from an SMS failure. It also allows us to reduce, or completely eliminate our regularly scheduled maintenance windows.
