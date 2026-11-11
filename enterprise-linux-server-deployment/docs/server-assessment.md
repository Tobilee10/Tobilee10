# Enterprise Linux Server Deployment – Server Assessment

## Introduction

This document records the technical assessment of the Ubuntu Linux server used in the Enterprise Linux Server Deployment project.

The assessment establishes the server's baseline configuration before applying security hardening, automation, monitoring, and other administrative configurations.

It will also be used to document the server's condition after implementation.


## Assessment Objectives

The assessment aims to:

- Identify the operating system and kernel version.
- Verify CPU and memory resources.
- Inspect disk partitions and available storage.
- Review network interfaces and connectivity.
- Check running services.
- Inspect user accounts and administrative privileges.
- Review SSH and firewall configurations.
- Identify potential security and operational concerns.
- Establish a baseline for future comparison.

## Server Information

|Attribute| Recorded Value
|----------|----------------
|Server hostname| ip-10-0-1-121
|Cloud provider| AWS
|Instance ID| i-0641701fd5c30a11c
|Instance type| t2.medium
|AWS region| us-east-2
|Operating system| Ubuntu 26.04.1 LTS
|Kernel version| Linux 7.0.0-1014-aws
|Private IP address| 10.0.1.121
|Public IP address| 18.219.51.94
|Assessment date|10-Nov-2026
|Administrator| ubuntu

## System Information Assessment

### Operating System

**Command:**
```bash
cat /etc/os-release
```
**Purpose:**

    Identify the Linux distribution, release, and operating system details.

![os-release]()

### Kernel Version

**Command:**

    uname -r

**Purpose:**

    Identify the running Linux kernel version.

![kernel-v]()

### Hostname

**Command:**

    hostnamectl

**Purpose:**

    Inspect the server hostname and operating system information.

![hostname]()

### CPU Assessment

**Command:**

    lscpu

**Purpose:**

    Inspect CPU architecture, processor count, and CPU characteristics.
![lscpu]

**Additional command:**

    nproc

**Purpose:**

    Identify the number of available processing units.

![nproc]

### Memory Assessment

**Command:**

    free -h

**Purpose:**

    Inspect total memory, used memory, available memory, and swap.
![memory]()

**Additional command:**

    swapon --show

**Purpose:**

    Check whether swap space is configured.

![swapon]()

### Disk and Storage Assessment

**Commands:**

```bash
df -h
```
![disk-space]

```bash
lsblk
```
![block-device]
```bash
sudo fdisk -l
```
![disk-partitioning]

**Purpose:**

- Identify mounted filesystems.
- Inspect available disk space.
- Identify attached block devices.
- Review disk partitions.


## Network Assessment

**Commands:**
```bash
ip addr
ip route
hostname -I
```
**Purpose:**

- Identify network interfaces.
- Inspect assigned IP addresses.
- Review routing configuration.
- Confirm network interface status.

Additional connectivity test:

ping -c 4 8.8.8.8

Purpose:

Test basic outbound network connectivity where ICMP traffic is permitted.

![network]

### User and Permission Assessment

**Commands:**
```bash
whoami
id
getent group sudo
```
**Purpose:**

- Identify the current administrative user.
- Inspect user and group memberships.
- Identify accounts with sudo privileges.

Additional command:

    getent passwd

**Purpose:**

    Review local account entries.

> Sensitive account information should not be published unnecessarily.

![user]

### SSH Service Assessment

**Command:**

    sudo systemctl status ssh --no-pager

**Purpose:**

    Verify whether the SSH service is active.
![ssh-status]

**Inspect SSH configuration:**

    sudo sshd -t

Purpose:

    Validate the SSH daemon configuration.
![ssh-confgiguration]

**Review effective SSH settings:**

    sudo sshd -T

**Purpose:**

    Inspect the effective SSH daemon configuration.
![ssh-setttings]


### Firewall Assessment

**Command:**

    sudo ufw status verbose

**Purpose:**

    Determine whether UFW is installed, enabled, and configured.

    Review the firewall rules before making changes.

![uncomplicated-firewall-status]()

### Running Services Assessment

**Commands:**

    systemctl --type=service --state=running

**Purpose:**

    Identify currently running system services.
![running-services]

**Check failed services:**

    sudo systemctl --failed

**Purpose:**

    Identify services that have entered a failed state.
![failed-services]


### System Load and Uptime

**Commands:**
```bash
uptime
top -b -n 1 | head -20
```

**Purpose:**

    Inspect server uptime, load averages, and current resource utilization.

![process]

### Log Assessment

**Review recent system messages:**

    sudo journalctl -p warning -n 50 --no-pager

**Purpose:**

Identify recent warning and error messages.

**Review SSH authentication logs where available:**

    sudo journalctl -u ssh -n 50 --no-pager

**Purpose:**

    Inspect recent SSH service events.

![ssh-service-event]()

### Initial Findings

This section will summarize the results of the initial server assessment.

|Area| Finding| Action Required
|-----|----------|--------------|
|Operating system| Pending| Verify OS release
|Kernel| Pending| Record kernel version
|CPU| Pending| Review available resources
|Memory| Pending| Review memory utilization
|Storage| Pending| Review disk usage
|Networking| Pending| Verify connectivity
|Users| Pending| Review privileges
|SSH| Pending| Review access configuration
|Firewall| Pending| Review firewall rules
|Services| Pending| Identify unnecessary services
|Logs| Pending| Investigate warnings and errors

### Post-Implementation Assessment

After completing the project, repeat the relevant assessment commands and compare the results.

|Area| Before Implementation| After Implementation
|-----|-------------------|--------------------
|Operating system| Pending| Pending
|Kernel| Pending| Pending
|CPU utilization| Pending| Pending
|Memory utilization| Pending| Pending
|Disk utilization| Pending| Pending
|SSH security| Pending| Pending
|Firewall| Pending| Pending
|Running services| Pending| Pending
|Monitoring| Pending| Pending
|Backup| Pending| Pending

### Assessment Conclusion

The server assessment provides a baseline for evaluating the effectiveness of the deployment and administration activities.

The findings will guide subsequent security hardening, configuration management, automation, monitoring, and troubleshooting activities.

All assessment results must reflect actual command outputs from the deployed server.