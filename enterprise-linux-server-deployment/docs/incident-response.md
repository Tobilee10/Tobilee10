Enterprise Linux Server Deployment – Incident Response Plan

1. Introduction

This document defines the procedures for identifying, investigating, containing, resolving, and documenting security and operational incidents affecting the Enterprise Linux Server Deployment environment.

The objective is to minimize service disruption, protect system resources, preserve evidence, and restore normal operations safely.

Project Status: Incident Response Plan – Prepared, Implementation Pending.

2. Objectives

The incident response process aims to:

- Detect security and operational incidents.
- Identify affected systems and services.
- Limit the impact of incidents.
- Preserve relevant logs and evidence.
- Restore normal server operations.
- Identify root causes.
- Prevent similar incidents from recurring.

3. Types of Incidents

The following incidents are considered within the project scope:

Incident| Description| Priority
SSH brute-force attempts| Repeated unauthorized login attempts| High
Unauthorized access| Suspicious or unauthorized account access| Critical
High CPU utilization| Unexpected resource consumption| Medium
Disk exhaustion| Server storage approaches capacity| High
Nginx outage| Web service becomes unavailable| High
Fail2ban failure| Intrusion prevention service stops working| High
Malware suspicion| Suspicious processes or files detected| Critical
Backup failure| Expected backup is missing or incomplete| High
Monitoring failure| Monitoring data becomes unavailable| Medium

Priority should be adjusted according to actual impact and exposure.

4. Incident Response Lifecycle

The project follows six stages:

1. Preparation.
2. Identification.
3. Containment.
4. Eradication.
5. Recovery.
6. Lessons learned.

5. Preparation

Before incidents occur:

- Maintain administrative access through approved methods.
- Keep the operating system updated.
- Configure SSH security.
- Configure UFW.
- Install and configure Fail2ban.
- Monitor system logs.
- Maintain verified backups.
- Document important services and configurations.
- Know how to access the server through AWS Systems Manager where configured.

Useful commands:

sudo systemctl --failed
sudo ufw status verbose
sudo fail2ban-client status
df -h
free -h

6. Incident Identification

When suspicious activity or service disruption is detected, collect information before making changes.

Review system logs:

sudo journalctl -p warning -n 100 --no-pager

Review SSH events:

sudo journalctl -u ssh -n 100 --no-pager

Review Fail2ban events:

sudo journalctl -u fail2ban -n 100 --no-pager

Inspect active processes:

ps aux --sort=-%cpu | head

Check disk and memory:

df -h
free -h

Record:

- Date and time.
- Affected server.
- Observed symptoms.
- Relevant logs.
- Services affected.
- Potential business impact.

7. Incident Containment

Containment aims to prevent an incident from spreading or causing further damage.

Possible actions include:

- Restricting suspicious network access through AWS Security Groups.
- Blocking confirmed malicious sources.
- Disabling compromised accounts.
- Isolating affected services.
- Restricting access to sensitive files.
- Preserving relevant logs and evidence.

For a suspected compromised EC2 instance, consider isolating its network access using a controlled AWS security group change while preserving an authorized investigation or recovery path.

Do not destroy the instance or delete evidence before the investigation is complete.

8. Incident Eradication

After containing the incident:

- Identify the root cause.
- Remove unauthorized accounts or access.
- Remove malicious files only after preserving evidence.
- Correct vulnerable configurations.
- Rotate compromised credentials and keys.
- Apply required security updates.
- Review SSH, UFW, and Fail2ban configurations.
- Verify that unauthorized access paths are closed.

Do not assume that removing one suspicious file fully resolves a compromise.

9. Incident Recovery

Recovery aims to restore normal operations safely.

Possible recovery activities:

- Restore verified backups where necessary.
- Restart affected services.
- Rebuild compromised systems when appropriate.
- Validate system configurations.
- Verify user access.
- Test application availability.
- Confirm monitoring is functioning.

Example service verification:

sudo systemctl status nginx --no-pager
sudo systemctl status ssh --no-pager
sudo systemctl status fail2ban --no-pager

Check system health:

uptime
free -h
df -h

10. Incident Scenarios and Response Procedures

10.1 SSH Brute-Force Attempts

Symptoms:

- Repeated authentication failures.
- Suspicious login attempts.
- Unexpected IP addresses attempting SSH access.

Investigation:

sudo journalctl -u ssh -n 100 --no-pager
sudo fail2ban-client status sshd

Response:

1. Identify suspicious source IP addresses.
2. Review Fail2ban activity.
3. Verify AWS Security Group restrictions.
4. Review SSH authentication settings.
5. Restrict confirmed malicious sources.
6. Continue monitoring authentication events.

10.2 Suspected Unauthorized Access

Symptoms:

- Unknown user accounts.
- Unexpected sudo activity.
- Unrecognized SSH sessions.
- Unusual file or configuration changes.

Investigation:

who
w
last
getent group sudo
sudo journalctl --since "1 hour ago" --no-pager

Response:

1. Preserve relevant evidence.
2. Identify the affected accounts.
3. Contain unauthorized access.
4. Review SSH keys and account permissions.
5. Rotate potentially compromised credentials.
6. Investigate the root cause.
7. Restore the server from a trusted state if necessary.

10.3 Nginx Service Outage

Symptoms:

- Website unavailable.
- HTTP errors.
- Nginx service stopped.

Investigation:

sudo systemctl status nginx --no-pager
sudo nginx -t
sudo journalctl -u nginx -n 100 --no-pager

Response:

1. Identify the cause of the outage.
2. Check configuration and file permissions.
3. Verify network access.
4. Correct configuration errors.
5. Restart or reload Nginx when safe.
6. Test service availability.

10.4 Disk Space Exhaustion

Symptoms:

- Files cannot be written.
- Services fail.
- Disk utilization reaches critical levels.

Investigation:

df -h
sudo du -xhd1 /var 2>/dev/null | sort -h

Response:

1. Identify the directories consuming storage.
2. Determine whether logs, backups, or application files are responsible.
3. Preserve required data.
4. Safely remove unnecessary files.
5. Review log rotation and backup retention.
6. Verify available disk space.

10.5 Fail2ban Service Failure

Symptoms:

- Fail2ban becomes inactive.
- SSH jail is unavailable.
- Repeated login attempts are not being blocked.

Investigation:

sudo systemctl status fail2ban --no-pager
sudo fail2ban-client status
sudo journalctl -u fail2ban -n 100 --no-pager

Response:

1. Identify the service failure.
2. Review jail configuration.
3. Validate the logging backend.
4. Correct configuration errors.
5. Restart Fail2ban.
6. Confirm the SSH jail is active.

10.6 Backup Failure

Symptoms:

- Backup script exits unsuccessfully.
- Expected backup files are missing.
- Backup files are incomplete.

Investigation:

Review script output, exit codes, permissions, disk space, and backup destination availability.

Response:

1. Identify the failure.
2. Verify the source data.
3. Correct permissions or storage issues.
4. Run the backup again.
5. Verify the resulting backup.
6. Perform a recovery test where appropriate.

11. Evidence Preservation

During an incident, preserve relevant evidence where practical.

Examples include:

- Authentication logs.
- System journal entries.
- Fail2ban events.
- Process information.
- Network configuration.
- Relevant configuration files.
- AWS resource and security group information.

Store evidence securely and restrict access to it.

Avoid publishing private IP information, usernames, authentication details, or sensitive logs in the public repository.

12. Incident Documentation Template

Use the following template for each incident:

Field| Details
Incident ID| Unique incident reference
Date and time| When the incident occurred
Affected component| Server or service
Incident category| Security or operational
Severity| Critical, High, Medium, or Low
Description| What happened
Detection method| How it was discovered
Root cause| Identified cause
Containment action| Action taken to limit impact
Recovery action| Action taken to restore service
Verification| How recovery was confirmed
Lessons learned| Preventive improvements

13. Post-Incident Review

After resolving an incident:

1. Review the incident timeline.
2. Identify the root cause.
3. Evaluate the effectiveness of the response.
4. Identify missing security controls.
5. Update documentation.
6. Implement preventive improvements.
7. Record lessons learned.

The purpose is continuous improvement, not simply restoring service.

14. Escalation and Communication

For incidents beyond the scope of the project:

- Preserve available evidence.
- Avoid making destructive changes.
- Escalate to an experienced administrator or security professional.
- Communicate the impact and actions taken.
- Maintain a record of decisions and recovery activities.

15. Conclusion

A structured incident response process helps administrators respond to security threats and operational disruptions in a controlled and repeatable manner.

This document establishes a practical foundation for incident detection, containment, investigation, recovery, and continuous improvement within the Enterprise Linux Server Deployment project.