# A Better Way of Scheduling Jobs on HPC Systems: Simultaneous Fair-Share

**Author:**
* Craig P Steffen, NCSA: University of Illinois

**Abstract:**
Typical HPC job scheduler software determines scheduling order by a linear sum of weighted priority terms. When a system has a rich mix of job types, this makes it difficult to maintain good productivity across diverse user groups. Currently-implemented fair-share algorithms tweak priority calculations based on \emph{past} job handling by modifying priority, but don't fully solve problems of queue-stuffing and various classes of under-served job types, because of coupling between different terms of the linear calculated priority .

This paper proposes a new scheme of scheduling jobs on an HPC system called "Simultaneous Fair-share'' (or "SFS'') that works by considering the jobs already committed to run in a given time slice and adjusting which jobs are selected to run accordingly. This allows high-throughput collaborations to get lots of jobs run, but avoids the problems of some groups starving out others due to job characteristics, all while keeping system administrators from having to directly manage job schedules. This paper presents Simultaneous Fair-share in detail, with examples, and shows testing results using a job throughput and scheduler simulation.
