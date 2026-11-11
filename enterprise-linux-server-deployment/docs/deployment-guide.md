# Enterprise Linux Server Deployment – Deployment Guide

## Introduction

This document provides the step-by-step procedure for deploying, configuring, securing, and managing an Ubuntu Linux server on Amazon Web Services (AWS).

The deployment demonstrates practical Linux system administration and DevOps practices using AWS EC2, Bash, Ansible, Nginx, monitoring tools, and security configurations.

Project Status: Deployment Guide – Prepared, Implementation Pending

## Deployment Objectives

The deployment aims to:

- Provision an Ubuntu Linux server on AWS.
- Establish secure administrative access.
- Perform an initial server assessment.
- Apply Linux security hardening.
- Automate administrative tasks using Bash.
- Manage server configuration using Ansible.
- Install and configure Nginx.
- Implement monitoring and backup procedures.
- Test and document the completed environment.

## Prerequisites

Before beginning deployment, ensure the following are available:

**Local workstation**

- Linux operating system.
- Internet connectivity.
- SSH client.
- Git.
- Bash.
- Python 3.
- Ansible.
- AWS CLI.

**AWS requirements**

- An active AWS account.
- Permission to create and manage EC2 resources.
- An approved AWS region.
- An approved project budget.
- A dedicated EC2 SSH key pair.

**Knowledge requirements**

- Basic Linux administration.
- SSH authentication.
- AWS EC2 fundamentals.
- Linux networking and permissions.
- Basic Bash scripting.
- Basic Ansible concepts.

## Infrastructure Configuration

The planned infrastructure configuration is:

|Component| Planned configuration|
|----------|-------------------|
|Cloud provider| AWS
|Region| us-east-2
|Operating system| Ubuntu Server 24.04 LTS
|Instance type| t3.medium
|vCPU| 2
|Memory| 4 GiB
|Root storage| 30 GiB gp3
|Storage encryption| Enabled
|Network| VPC and public subnet
|Access| Restricted SSH and optional SSM
|Monitoring| Basic EC2 monitoring


## Local Workstation Preparation

Update the local Linux workstation:
```bash
sudo apt update
sudo apt upgrade -y
```
> Install the required tools where they are not already available:

```bash
sudo apt install -y \
  git \
  curl \
  wget \
  unzip \
  openssh-client \
  python3 \
  python3-pip \
  python3-venv
```
**Verify the installed tools:**
```bash
git --version
ssh -V
python3 --version
ansible --version
aws --version
```
If Ansible or AWS CLI is missing, install it using the appropriate official installation method.

## AWS EC2 Provisioning

### Step 1: Configure AWS infrastructure

Prepare the following resources:

- VPC.
- Public subnet.
- Internet Gateway and route table.
- EC2 security group.
- EC2 key pair.

### Step 2: Create the EC2 instance

Launch an EC2 instance using the approved configuration.

Planned settings:

- Name: enterprise-linux-server.
- AMI: Ubuntu Server 24.04 LTS.
- Instance type: t2.medium.
- Storage: 30 GiB encrypted gp3.
- Key pair: enterprise-linux-server-key.
- Security group: dedicated project security group.

### Step 3: Configure security group rules

Apply the minimum required network access.

Protocol| Port| Source| Purpose
TCP| 22| Approved administrator IP| SSH
TCP| 80| Only if required| HTTP
![security-group]()

Do not expose SSH or monitoring interfaces to the entire internet unnecessarily.

### Step 4: Verify instance status

Confirm that:

- Instance state is running.
- Instance status checks pass.
- Public IP is available if using direct SSH.
- The correct security group is attached.
- The intended EBS volume is attached.

![instance-status]

## Secure Server Access

Set appropriate permissions on the private key:

  chmod 400 enterprise-linux-server-key.pem
![private-key-permission](../)
**Connect to the instance:**

  ssh -i enterprise-linux-server-key.pem ubuntu@18.219.51.94

![screenshot-ssh-login]()

**Verify the connection:**

```bash
whoami
hostname
uptime
```

## Initial Server Assessment

After connecting, collect baseline system information.
```bash
hostnamectl
uname -r
cat /etc/os-release
lscpu
free -h
df -h
lsblk
ip addr
ip route
sudo systemctl --failed
sudo systemctl status ssh --no-pager
sudo ufw status verbose
```
The actual result is recorded in:
  docs/server-assessment.md

This baseline will help compare the server's condition before and after configuration.

## Linux Security Hardening

The following security measures are planned:

1. Review SSH configuration.
2. Restrict SSH access to approved sources.
3. Review administrative users and groups.
4. Apply least-privilege permissions.
5. Configure UFW firewall rules.
6. Apply security updates.
7. Review running services.
8. Configure log management.
9. Verify file permissions.
10. Document security changes.

Before changing SSH settings, validate the configuration and keep an existing administrative session open.

  **SSH configuration validation:**

sudo sshd -t

Do not disable password authentication or change SSH access settings until key-based access has been tested successfully.

The documented implementation control is in:

  docs/security-hardening.md

##  Bash Automation

The project will use Bash scripts to automate routine administrative operations.

Planned scripts:

|Script| Responsibility |
|---------|--------------|
|scripts/system-health-check.sh| Check system health |
|scripts/disk-monitor.sh| Monitor disk usage |
|scripts/backup.sh| Perform backup operations |
|scripts/user-management.sh| Assist with user management |

**Make scripts executable:**

  chmod +x scripts/*.sh

Test each script individually before using it in an automated workflow.

## Ansible Configuration Management

The local Linux workstation will act as the Ansible control node.

### Step 1: Configure inventory

Create or update:

  ansible/inventory/hosts.ini

```ini
[linux_servers]
enterprise-linux-server ansible_host=<PUBLIC_IP>
ansible_user=ubuntu 
ansible_ssh_private_key_file=~/.ssh/enterprise-linux-server-key.pem
```

Use the actual IP address and secure private-key location.

### Step 2: Test connectivity

ansible linux_servers -i ansible/inventory/hosts.ini -m ping

Step 3: Implement playbooks

Create playbooks for:

- Package management.
- User management.
- SSH hardening.
- Firewall configuration.
- Nginx installation.
- Service management.

Step 4: Validate configuration

Run Ansible syntax checks before execution:

ansible-playbook --syntax-check \
  ansible/playbooks/site.yml

Run playbooks against the intended inventory and verify the resulting configuration.

1.  Nginx Deployment

Install Nginx using the approved package-management method or an Ansible playbook.

For manual installation:

sudo apt update
sudo apt install -y nginx

Enable and start the service:

sudo systemctl enable nginx
sudo systemctl start nginx

Verify service status:

sudo systemctl status nginx --no-pager

Validate the configuration:

sudo nginx -t

If HTTP access is enabled, test the server using its public address.

13. Monitoring Implementation

Monitoring will be introduced after the server's baseline configuration is complete.

Planned monitoring capabilities:

- CPU utilization.
- Memory utilization.
- Disk utilization.
- Network activity.
- Service availability.

Prometheus and Grafana are the planned monitoring tools.

The final deployment approach will consider server capacity, network exposure, and AWS costs.

Do not expose Grafana or Prometheus administrative interfaces publicly without appropriate access controls.

14. Backup Implementation

The backup procedure will demonstrate:

- Identifying important files.
- Creating backups.
- Verifying backup integrity.
- Managing backup retention.
- Performing recovery tests.

The backup script will be tested using non-critical sample data first.

Backup locations, retention periods, and storage costs must be documented.

15. Testing and Verification

After implementation, perform the following checks.

Infrastructure

- EC2 instance is running.
- EC2 status checks pass.
- EBS volume is attached and encrypted.
- Security group rules match the approved design.

Linux

- SSH access works.
- Administrative permissions are correct.
- Firewall rules are active.
- Required services are running.
- Disk and memory utilization are healthy.

Automation

- Bash scripts execute successfully.
- Ansible connectivity succeeds.
- Playbooks pass syntax validation.
- Configuration changes are verified.

Web server

- Nginx is running.
- Nginx configuration passes validation.
- HTTP or HTTPS responds as configured.

Monitoring and backup

- Expected metrics are available.
- Dashboards display the intended metrics.
- Backup files are created and verified.
- Recovery procedures are tested.

Record test results and evidence in the repository.

16. Troubleshooting

Common issues and their resolution procedures will be documented in:

docs/troubleshooting.md

Examples include:

- SSH connection failures.
- Permission denied errors.
- Ansible connectivity problems.
- Nginx startup failures.
- Firewall restrictions.
- Disk space exhaustion.
- Monitoring service failures.

17. Security and Operational Considerations

- Never commit passwords, API keys, or private keys.
- Use least-privilege permissions.
- Restrict inbound network traffic.
- Keep the operating system updated.
- Validate configuration before restarting critical services.
- Monitor resource utilization.
- Maintain verified backups.
- Review AWS costs throughout the project.

18. Decommissioning

After completing the project and collecting evidence:

1. Confirm that all required documentation is saved locally.
2. Preserve screenshots, command outputs, and configuration examples.
3. Check for important data that needs to be retained.
4. Terminate the project EC2 instance.
5. Review associated EBS volumes.
6. Review snapshots and other created resources.
7. Remove unused project-specific resources.
8. Verify that no unnecessary billable resources remain.

Refer to:

docs/decommissioning-guide.md

Do not delete shared resources or anything outside this project's scope.

19. Deployment Evidence

The following evidence will be collected:

- EC2 instance configuration.
- Successful SSH connection.
- Linux system assessment.
- Security hardening verification.
- Firewall configuration.
- Ansible connectivity test.
- Nginx service status.
- Bash script execution.
- Monitoring dashboards.
- Backup and recovery test results.

Store appropriate evidence in:

screenshots/

Remove public IPs, private information, credentials, and other sensitive details before publishing evidence.

20. Conclusion

This deployment guide provides a repeatable approach to building and managing a Linux server environment on AWS.

The project will demonstrate practical skills in Linux system administration, AWS infrastructure, security, automation, monitoring, backup, troubleshooting, and operational documentation.

The guide will be updated throughout implementation to reflect the actual commands, configurations, test results, and lessons learned.