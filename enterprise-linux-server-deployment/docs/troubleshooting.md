Enterprise Linux Server Deployment – Troubleshooting Guide

1. Introduction

This document provides troubleshooting procedures for common problems encountered while deploying, securing, configuring, and managing the Ubuntu Linux server.

It serves as an operational reference for identifying issues, investigating their causes, applying corrective actions, and verifying successful recovery.

Project Status: Troubleshooting Guide – Prepared.

2. Troubleshooting Methodology

Use the following approach when investigating an issue:

1. Identify and clearly describe the problem.
2. Determine the affected server, service, or component.
3. Collect relevant logs and command outputs.
4. Identify possible causes.
5. Apply the safest corrective action.
6. Verify that the issue is resolved.
7. Document the root cause and resolution.

Avoid making multiple unrelated changes at once.

3. SSH Connection Problems

Symptoms

- Connection timed out.
- Permission denied.
- Connection refused.
- Unable to connect to the EC2 instance.

Diagnostic Commands

ssh -v -i ~/.ssh/enterprise-linux-server-key.pem ubuntu@<PUBLIC_IP>

Check SSH service:

sudo systemctl status ssh --no-pager

Validate SSH configuration:

sudo sshd -t

Possible Causes

- Incorrect public IP address.
- Incorrect private key.
- Incorrect key permissions.
- AWS Security Group blocking port 22.
- UFW blocking SSH.
- SSH service stopped.
- Incorrect SSH username.

Resolution

Verify the EC2 public IP, key path, username, and security group rules.

Check private key permissions:

chmod 400 ~/.ssh/enterprise-linux-server-key.pem

Ensure SSH is running:

sudo systemctl enable --now ssh

4. Permission Denied Errors

Symptoms

- Unable to access files.
- Permission denied when executing scripts.
- Unable to perform administrative operations.

Diagnostic Commands

whoami
id
ls -l <FILE>

Possible Causes

- Incorrect file ownership.
- Insufficient permissions.
- User not authorized for sudo.
- Script does not have execute permission.

Resolution

Review file ownership and permissions.

Example:

chmod +x scripts/system-health-check.sh

For administrative commands:

sudo <COMMAND>

Grant additional privileges only when required.

5. UFW Firewall Problems

Symptoms

- SSH connection fails after firewall changes.
- Web server cannot be reached.
- Required ports are blocked.

Diagnostic Commands

sudo ufw status verbose
sudo ufw status numbered

Possible Causes

- SSH allow rule missing.
- Incorrect source IP.
- Required application port blocked.
- Firewall rules conflict with the intended network design.

Resolution

Review the firewall rules and restore the necessary access.

Example:

sudo ufw allow from <ADMIN_IP>/32 to any port 22 proto tcp

Do not disable the firewall without understanding the consequences.

6. Fail2ban Problems

Symptoms

- Fail2ban service is inactive.
- SSH jail is not enabled.
- Legitimate administrator IP is banned.
- Authentication failures are not being detected.

Diagnostic Commands

sudo systemctl status fail2ban --no-pager
sudo fail2ban-client status
sudo fail2ban-client status sshd

Inspect logs:

sudo journalctl -u fail2ban -n 50 --no-pager

Possible Causes

- Incorrect jail configuration.
- SSH jail disabled.
- Unsupported logging backend.
- Incorrect authentication log configuration.
- Fail2ban service not running.

Resolution

Validate the configuration and review the relevant jail settings.

Restart the service after correcting configuration:

sudo systemctl restart fail2ban

If a legitimate IP address is banned, verify its identity before unbanning:

sudo fail2ban-client set sshd unbanip <IP_ADDRESS>

7. Nginx Service Problems

Symptoms

- Website is inaccessible.
- Nginx fails to start.
- HTTP returns an error.
- Configuration test fails.

Diagnostic Commands

sudo systemctl status nginx --no-pager
sudo nginx -t
sudo journalctl -u nginx -n 50 --no-pager

Possible Causes

- Incorrect Nginx configuration.
- Port conflict.
- Missing configuration files.
- Incorrect file permissions.
- Firewall or AWS Security Group restrictions.

Resolution

Validate the Nginx configuration:

sudo nginx -t

Reload after successful validation:

sudo systemctl reload nginx

Restart only when necessary:

sudo systemctl restart nginx

8. High Disk Utilization

Symptoms

- Disk usage reaches critical levels.
- Applications cannot write files.
- Services fail because storage is exhausted.

Diagnostic Commands

df -h
lsblk

Identify large directories:

sudo du -xhd1 /var 2>/dev/null | sort -h

Check journal disk usage:

sudo journalctl --disk-usage

Possible Causes

- Large log files.
- Unnecessary packages.
- Application-generated files.
- Unmanaged backups.
- Insufficient storage capacity.

Resolution

Identify the files consuming space before deleting anything.

Review package cache:

sudo apt clean

Review journal retention and configure appropriate limits if required.

Never delete system files or application data without confirming their purpose.

9. High Memory Utilization

Symptoms

- Server becomes slow.
- Applications are terminated unexpectedly.
- Services fail due to insufficient memory.

Diagnostic Commands

free -h
top
ps aux --sort=-%mem | head

Possible Causes

- Applications consuming excessive memory.
- Too many running services.
- Memory leaks.
- Insufficient instance memory.

Resolution

Identify the process responsible before restarting or terminating it.

Review application resource requirements and consider resizing the EC2 instance if justified.

10. High CPU Utilization

Symptoms

- Slow application response.
- High system load.
- Increased CPU utilization.

Diagnostic Commands

top
uptime
ps aux --sort=-%cpu | head

Possible Causes

- CPU-intensive processes.
- Uncontrolled application workloads.
- Background jobs.
- Resource limitations.

Resolution

Identify the responsible process, investigate its behavior, and optimize or restart it when appropriate.

11. Ansible Connectivity Problems

Symptoms

- Ansible ping fails.
- SSH authentication errors.
- Host unreachable.
- Playbook execution fails.

Diagnostic Commands

ansible linux_servers -i ansible/inventory/hosts.ini -m ping -vvv

Test SSH directly:

ssh -i ~/.ssh/enterprise-linux-server-key.pem ubuntu@<PUBLIC_IP>

Possible Causes

- Incorrect inventory configuration.
- Incorrect private key path.
- SSH connectivity problems.
- Incorrect remote username.
- Python interpreter unavailable on the managed server.

Resolution

Review the inventory, SSH configuration, and connectivity before rerunning the playbook.

12. Package Installation Problems

Symptoms

- Unable to install packages.
- Package repository errors.
- Dependency conflicts.

Diagnostic Commands

sudo apt update
sudo apt --fix-broken install

Possible Causes

- Repository connectivity issues.
- Package index problems.
- Dependency conflicts.
- Insufficient disk space.

Resolution

Review the package manager output, verify connectivity, and correct the underlying issue before attempting installation again.

13. Monitoring Problems

Symptoms

- Prometheus target is down.
- Grafana dashboards display no data.
- Metrics are missing.
- Monitoring services fail to start.

Diagnostic Commands

sudo systemctl status prometheus --no-pager
sudo systemctl status grafana-server --no-pager

Inspect service logs:

sudo journalctl -u prometheus -n 50 --no-pager
sudo journalctl -u grafana-server -n 50 --no-pager

Possible Causes

- Incorrect monitoring configuration.
- Service unavailable.
- Incorrect target address.
- Network connectivity problems.
- Exporter not running.

Resolution

Verify the monitoring configuration, target availability, service status, and network access.

14. System Service Failures

Symptoms

- A service fails to start.
- Application becomes unavailable.
- Service enters a failed state.

Diagnostic Commands

sudo systemctl --failed
sudo systemctl status <SERVICE_NAME> --no-pager
sudo journalctl -u <SERVICE_NAME> -n 50 --no-pager

Resolution

Inspect the error messages, identify the root cause, correct the configuration, and restart the affected service when safe.

15. Troubleshooting Record

Record significant incidents using this template:

Field| Description
Date and time| When the issue occurred
Affected component| Service or infrastructure component
Symptoms| What happened
Root cause| Identified cause
Corrective action| Action taken
Verification| How resolution was confirmed
Lessons learned| What can prevent recurrence

16. General Operational Recommendations

- Collect evidence before changing configurations.
- Check service logs before restarting services.
- Validate configurations before applying changes.
- Avoid unnecessary server reboots.
- Preserve existing administrative access during security changes.
- Monitor disk, memory, and CPU utilization.
- Document all significant changes.
- Verify that the service works after every corrective action.

17. Conclusion

Effective troubleshooting requires structured investigation, accurate diagnosis, safe corrective actions, and verification.

This guide provides a practical reference for diagnosing common Linux, AWS, networking, security, automation, and monitoring problems encountered during the project.