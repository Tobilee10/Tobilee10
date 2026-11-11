EC2 Server Decommissioning Guide

1. Purpose

This guide explains how to safely decommission the EC2 instance used for the Enterprise Linux Server Deployment project.

Decommissioning means shutting down and removing infrastructure resources that are no longer required.

The objectives are to:

- Prevent unnecessary AWS charges.
- Remove unused cloud resources safely.
- Preserve important project documentation and evidence.
- Verify that no billable resources have been left behind.

«Important: Do not decommission the server until testing, documentation, and evidence collection are complete.»

2. Scope

This guide covers the following resources:

- EC2 instance
- EBS root volume and any additional EBS volumes
- Elastic IP addresses, if any were allocated
- EBS snapshots created for this project
- Project-specific security groups
- Project-specific key pair
- Any additional resources created specifically for this project

It does not cover shared AWS resources that may be used by other projects.

3. Pre-Decommissioning Checklist

Before removing resources, confirm the following:

- [ ] All deployment tasks are complete.
- [ ] All tests and verification checks have passed.
- [ ] Project documentation is updated.
- [ ] Screenshots and command outputs have been saved locally.
- [ ] Important configuration files have been backed up.
- [ ] No other project depends on this EC2 instance.
- [ ] No important data remains on the server.
- [ ] The EC2 instance ID and related resource IDs have been recorded.

4. Preserve Project Evidence

Before terminating the instance, preserve relevant evidence locally.

Recommended evidence includes:

- Operating system and kernel information.
- CPU, memory, and disk information.
- SSH hardening configuration.
- Firewall status.
- Fail2ban status.
- Running services.
- Nginx status and test results, if installed.
- Ansible execution results.
- Backup and monitoring verification results, if implemented.
- Relevant logs and troubleshooting records.

Store the evidence in the project's "screenshots/" directory or another documented evidence folder.

Do not store private SSH keys, passwords, access tokens, or other secrets in the public GitHub repository.

5. Identify Project Resources

Review the AWS resources created for this project.

Record the following:

Resource| Details
EC2 instance ID| To be recorded
Instance name| enterprise-linux-server
AWS region| us-east-2
EBS volume IDs| To be recorded
Security group ID| To be recorded
Key pair name| enterprise-linux-server-key
Elastic IP| If allocated
Snapshot IDs| If created

Make sure each resource belongs to this project before deleting it.

6. Terminate the EC2 Instance

1. Sign in to the AWS Management Console.
2. Open the EC2 service.
3. Select the correct AWS region.
4. Navigate to Instances.
5. Identify the instance named "enterprise-linux-server".
6. Confirm its instance ID.
7. Select the instance.
8. Choose Instance state → Terminate instance.
9. Review the confirmation message.
10. Confirm termination.

Important: Termination is irreversible. Do not terminate an instance that contains data or resources needed by another project.

7. Verify EBS Volume Cleanup

After termination:

1. Navigate to EC2 → Volumes.
2. Check whether the project's EBS volumes have been deleted.
3. Review any remaining volumes.
4. Delete only volumes that are confirmed to belong to this project and are no longer needed.

Check the EC2 instance's termination settings. If the root volume was configured to be retained on termination, it may remain and continue to incur storage charges.

8. Release Elastic IP Addresses

If an Elastic IP address was allocated specifically for this project:

1. Navigate to EC2 → Elastic IP addresses.
2. Identify the project-specific address.
3. Confirm that it is no longer associated with a resource.
4. Release the address if it is no longer required.

Do not release an address used by another application or environment.

9. Delete Unnecessary Snapshots

If snapshots were created for this project:

1. Navigate to EC2 → Snapshots.
2. Identify snapshots owned by this project.
3. Confirm that no recovery or retention requirement exists.
4. Delete only snapshots that are no longer needed.

Snapshots can continue to incur storage charges even after an EC2 instance is terminated.

10. Remove Unused Security Groups

1. Navigate to EC2 → Security Groups.
2. Identify security groups created exclusively for this project.
3. Confirm that no other resource depends on them.
4. Delete the unused security groups.

AWS will prevent deletion of a security group that is still associated with certain resources or referenced by other security groups.

Do not delete default or shared security groups.

11. Remove the Project Key Pair

If "enterprise-linux-server-key" was created exclusively for this project and is no longer needed:

1. Navigate to EC2 → Key Pairs.
2. Locate the project key pair.
3. Confirm that it is not needed by another instance.
4. Delete the key pair from AWS.

Deleting the AWS key pair does not automatically delete the downloaded private key file from your local computer. Securely remove the local private key only when you are certain it is no longer needed.

Never upload private keys to GitHub.

12. Final AWS Resource Audit

Review the AWS console to ensure that no unnecessary project resources remain.

Check:

- EC2 instances
- EBS volumes
- EBS snapshots
- Elastic IP addresses
- Project-specific security groups
- Project-specific key pairs
- Any other services or resources created during the project

Also check AWS Billing and Cost Management for any remaining charges.

Remember that billing information may take time to reflect recent resource changes.

13. Decommissioning Verification

Run through this checklist after cleanup:

- [ ] EC2 instance is terminated.
- [ ] Unneeded EBS volumes are deleted.
- [ ] Unused Elastic IP addresses are released.
- [ ] Unneeded snapshots are deleted.
- [ ] Unused project security groups are removed.
- [ ] Unneeded key pairs are removed from AWS.
- [ ] No shared resources were accidentally deleted.
- [ ] Project evidence is preserved locally.
- [ ] AWS Billing has been reviewed.

14. Lessons Learned

Decommissioning is an important part of infrastructure lifecycle management.

Key lessons include:

- Cloud resources should be removed when they are no longer required.
- Infrastructure ownership must be clear before deleting resources.
- Data and evidence should be preserved before termination.
- EBS volumes and snapshots may continue to incur costs after an instance is terminated.
- Resource cleanup should be verified rather than assumed.
- Cost management is part of responsible cloud administration.

15. Future Improvements

Possible improvements include:

- Automating resource cleanup using Terraform.
- Applying resource tags for easier ownership identification.
- Using AWS Config to monitor resource configuration.
- Creating automated cost alerts.
- Maintaining an infrastructure inventory.
- Introducing a formal approval process for production decommissioning.

16. Conclusion

A successful infrastructure deployment does not end when the server becomes operational. Responsible infrastructure management also includes maintenance, monitoring, backup, incident response, and safe decommissioning.

This process helps reduce unnecessary cloud expenses, protect important information, and maintain good operational practices.

17. Author

Project: Enterprise Linux Server Deployment
Role: Linux System Administrator / DevOps Engineer
GitHub: https://github.com/tobilee10