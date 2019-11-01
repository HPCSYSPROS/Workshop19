# Arbiter: Dynamically Limiting Resource Consumption on Login Nodes

**Authors:**
* Dylan Gardner, University of Utah
* Robben Migacz, University of Utah
* Brian Haymore, University of Utah

**Abstract:**
Arbiter is a service that addresses the misuse of login nodes by automatically enforcing policies using Linux cgroups. When users log in, Arbiter sets a default hard memory and CPU limit on the user to prevent them from dominating the whole machine’s memory and CPU resources. To enforce policies, Arbiter tracks the usage of individual users over a set interval and looks for policy violations. When a violation occurs, the violating user is emailed about what behavior constituted the violation and the acceptable usage policy for login nodes. In addition, Arbiter also temporarily lowers the hard memory and CPU limit to discourage excessive usage. The length of time and severity of the lower hard limit depends on whether a user has repeatedly violated policies to penalize users for continued excessive usage. The result of the Arbiter service is that login nodes stay responsive, with users informed of policies and discouraged from running computationally heavy jobs on login nodes.

**Original Paper:**
https://doi.org/10.1145/3332186.3333043

**Source Code:**
https://gitlab.chpc.utah.edu/arbiter2/arbiter2
