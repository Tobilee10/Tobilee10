# Enterprise Linux Server Deployment – Security Hardening Guide

## Introduction

This document describes the security measures planned for the Enterprise Linux Server Deployment project.

The objective is to secure an Ubuntu Linux server hosted on AWS EC2 by implementing practical Linux security controls, restricting unauthorized access, protecting administrative services, and improving system visibility.

The security implementation follows the principles of:

- Defense in depth.
- Least privilege.
- Secure configuration.
- Restricted network access.
- Continuous monitoring.
- Regular security updates.

## Security Objectives

The security hardening process aims to:

- Secure remote administrative access.
- Restrict unnecessary network traffic.
- Protect SSH against brute-force attacks.
- Manage users and permissions securely.
- Keep the operating system updated.
- Minimize unnecessary running services.
- Protect sensitive configuration files.
- Monitor authentication and system events.
- Maintain secure backup procedures.
- Verify the effectiveness of implemented controls.

## Security Architecture

The server will use multiple security layers:

|Security Layer| Security Control| Purpose|
|----------------|---------------|---------------|
|AWS Network| Security Groups| Restrict network traffic
|Authentication| SSH keys| Secure remote login
|Access Control| Linux users and groups| Enforce least privilege
|Host Firewall| UFW| Control server traffic
|Intrusion Prevention| Fail2ban| Ban repeated authentication offenders
|System Maintenance| Security updates| Address known vulnerabilities
|File Security| Linux permissions| Protect sensitive files
|Monitoring| System logs| Detect suspicious activities
|Backup| Backup procedures| Support recovery

## SSH Security Hardening

### Purpose

SSH provides remote administrative access to the Linux server. Poor SSH configuration can expose the server to unauthorized access attempts.

The objective is to strengthen SSH authentication and restrict unnecessary access.

### SSH Security Measures

- Use SSH key-based authentication.
- Restrict SSH access through the AWS security group.
- Disable direct root login.
- Disable password authentication after verifying key-based access.
- Restrict administrative access to authorized users.
- Use appropriate SSH configuration file permissions.
- Monitor authentication logs.

### Inspect SSH Configuration

```bash
sudo sshd -t
sudo sshd -T
```
![inspect-ssh]

**Inspect the SSH configuration:**

    sudo nano /etc/ssh/sshd_config

**Recommended security settings:**

```bash
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
MaxAuthTries 3
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
ClientAliveInterval 300
ClientAliveCountMax 3
```
![ssh-config]

### Validate and Apply Changes

**Validate the configuration:**

    sudo sshd -t

**Reload SSH:*

    sudo systemctl reload ssh

![validate-ssh]

Open a second terminal and confirm that a new SSH connection works before closing the existing session.

![second-terminal-login]


## UFW Firewall Configuration

### Purpose

Uncomplicated Firewall (UFW) provides a straightforward interface for managing Linux host firewall rules.

The objective is to allow only necessary network traffic.

### Inspect Firewall Status

    sudo ufw status verbose
![ufw-status]

### Configure Default Policies

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```
![ufw-default]()

### Allow SSH Access

Before enabling UFW, allow SSH from the approved administrator IP address.

    sudo ufw allow from <ADMIN_IP>/32 to any port 22 proto tcp
![ssh-admin]

> **NB:** Replace "<ADMIN_IP>" with the actual trusted public IP address.

    If the administrator's public IP changes, update the firewall rule before attempting a new SSH connection.

### Allow Web Traffic When Required

For an HTTP web server:

    sudo ufw allow 80/tcp

![web-traffic]


### Enable UFW

    sudo ufw enable

**Verify the rules:**

    sudo ufw status numbered
![ufw-enable]()

> **NB:** Security consideration ---> AWS Security Groups and UFW operate at different layers. Both must be configured consistently. Do not expose unnecessary ports.

## Fail2ban – Intrusion Prevention

### Purpose

Fail2ban monitors authentication logs and temporarily bans IP addresses that repeatedly fail authentication.

It helps reduce SSH brute-force attempts and other automated login attacks.

### 6.2 Install Fail2ban

```bash
sudo apt update
sudo apt install -y fail2ban
```
![fail2ban-install]

### Configure Fail2ban

Intrusion Prevention Setup

A custom jail.local file was created `/etc/fail2ban/jail.local` to override default configuration file so package updates do not overwrite custom rules.

    sudo nano /etc/fail2ban/jail.local

**Add:**

```bash
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
```
![fail2ban-config]

**Configuration explanation:**

|Setting| Value| Explanation
|-------|--------|---------
|bantime| 1h| Ban duration
|findtime| 10m| Period used to count failed attempts
|maxretry| 5| Failed attempts allowed
|backend| systemd| Uses supported systemd journal logging
|enabled| true| Enables SSH protection

### Enable and Start Fail2ban

    sudo systemctl enable --now fail2ban
![enable-fail2ban]

**Verify service status:**

    sudo systemctl status fail2ban --no-pager
![status-fail2ban]

### Verify SSH Protection

**Check active jails:**

    sudo fail2ban-client status
![active-jail]

**Check the SSH jail:**

    sudo fail2ban-client status sshd
![jail-list]

### Unban an IP Address

When a legitimate administrator is accidentally banned, inspect the situation and unban the address if appropriate:

    sudo fail2ban-client set sshd unbanip <IP_ADDRESS>

### Review Fail2ban Logs

    sudo journalctl -u fail2ban --no-pager

### Security Considerations

- Fail2ban does not replace SSH hardening.
- Fail2ban does not replace AWS Security Groups or UFW.
- Keep an alternative administrative access method available.
- Avoid testing bans from your only administrative connection.
- Configure trusted IP exclusions carefully.
- Verify that the SSH jail is actually monitoring the intended authentication logs.

## User and Permission Management

### Purpose

Linux user and permission management ensures that users can access only the resources necessary for their responsibilities.

### Inspect Existing Users
```bash
whoami
id
getent group sudo
```

**Review local account entries:**

    getent passwd

### Create an Administrative User

    sudo useradd -m -s /bin/bash sysadmin
![useradd]

**User requires administrative privileges:**

    sudo usermod -aG sudo sysadmin

Verify group membership:

    id sysadmin

![verify]

### Apply Appropriate Permissions

```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```
Verify ownership and permissions:
```
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```
![verify-ownership]

### Security Considerations

- Avoid sharing administrator accounts.
- Grant sudo access only when required.
- Use appropriate ownership and file permissions.
- Remove unnecessary accounts.
- Review user access periodically.

## Operating System Security Updates

### Purpose

Keeping the operating system updated helps address known vulnerabilities, improve stability, and maintain security.

### Update Package Information

    sudo apt update

### Apply Available Updates

    sudo apt upgrade

Review package changes before confirming the operation.

### Review Available Security Updates

    apt list --upgradable

![list-upgrades]


## Log Monitoring and Auditing

System logs provide information about authentication attempts, service failures, administrative activities, and operational problems.

### Review System Logs

    sudo journalctl -p warning -n 50 --no-pager

### Review SSH Logs

    sudo journalctl -u ssh -n 50 --no-pager

### Review Fail2ban Logs

    sudo journalctl -u fail2ban -n 50 --no-pager


##  AWS-Level Security Controls

The Linux server will also use AWS security controls.

### Security Groups

- Allow SSH only from approved administrator IP addresses.
- Open HTTP and HTTPS only when needed.
- Do not expose monitoring interfaces publicly.
- Remove unused inbound rules.

### Encryption

Enable encryption for the server's EBS volume to protect stored data.

### IAM and Administrative Access

- Follow least-privilege IAM practices.
- Avoid sharing AWS access keys.
- Prefer IAM roles for AWS service access where appropriate.
- Use AWS Systems Manager Session Manager where configured.


## Backup and Recovery Security

Backup procedures should protect the availability and integrity of important data.

Security practices include:

- Restricting backup file permissions.
- Avoiding plaintext credentials in backup scripts.
- Protecting backup destinations.
- Encrypting backups where supported.
- Verifying backup integrity.
- Testing recovery procedures.
- Applying appropriate retention policies.

## Security Verification Checklist

The following checklist will be completed after implementation.

|Security Control| Verification Method| Status
|------------------|-----------------|----------
SSH key authentication| Test SSH login| successful
Root SSH login disabled| Inspect effective SSH settings| successful
Password authentication disabled| Inspect effective SSH settings| successful
SSH access restricted| Review AWS Security Group and UFW| successful
UFW enabled| "sudo ufw status verbose"| successful
Fail2ban installed| "fail2ban-client --version"| successful
SSH jail active| "fail2ban-client status sshd"| successful
User privileges reviewed| "id" and "getent group sudo"| successful
System updated| Review package updates| successful
Logs reviewed| Inspect journal and authentication logs| successful
EBS encryption enabled| Inspect EC2 volume settings| successful


##  Security Incident Response

If suspicious activity is detected:

1. Identify the affected service or account.
2. Review authentication and system logs.
3. Identify suspicious IP addresses and processes.
4. Restrict access where necessary.
5. Investigate the source and impact.
6. Restore secure configurations.
7. Verify that services are operating correctly.
8. Document the incident and corrective actions.

Refer to "docs/incident-response.md" for the incident response procedure.

## Security Limitations

This project is a practical learning and portfolio environment.

The implemented controls demonstrate foundational Linux and AWS security practices but do not automatically establish production-grade compliance or eliminate all security risks.

Additional controls may be necessary depending on the application's sensitivity, threat model, regulatory requirements, and operational environment.

## Implementation Record

Record each security change as it is implemented.

Date| Security Control| Action Taken| Verification Result
Pending| SSH hardening| Disabled oot login & password auth| successful
Pending| UFW firewall| Enabled firewall & restricted ports| successful
Pending| Fail2ban| Configured SSH jail & activate monitoring| successful
Pending| User management| Audited sudo priviledges & user account| successful
Pending| System updates| Applied latest security patches| successful


##  Conclusion

Security hardening is an essential part of Linux server administration.

By combining SSH security, firewall configuration, Fail2ban, user management, system updates, service hardening, logging, and AWS security controls, this project demonstrates a layered approach to protecting Linux infrastructure.

All security controls must be implemented, tested, and documented using actual results from the deployed server.