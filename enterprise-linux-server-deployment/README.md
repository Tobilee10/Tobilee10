# Enterprise Linux Server Deployment & Hardening (AWS EC2)

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-EC2-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-Automation-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-Web_Server-009639?style=for-the-badge&logo=nginx&logoColor=white)
![Status](https://img.shields.io/badge/Status-In_Progress-yellow?style=for-the-badge)

## Project Overview

This repository documents the end-to-end deployment, security hardening, automated management, and monitoring of an enterprise Ubuntu Server instance on AWS EC2. 

Designed around real-world Linux System Administration and DevOps practices, this project eliminates manual configuration drift by leveraging declarative configuration management with **Ansible**, automated administrative workflows via **Bash**, network perimeter isolation using **UFW**, and kernel/SSH hardening.

## Problem Statement

Organizations depend on Linux servers to host applications, manage services, store data, and support business operations.

Poor server configuration, weak access controls, inadequate monitoring, manual administration, and insufficient backup procedures can lead to security vulnerabilities, service interruptions, and operational inefficiencies.

This project addresses these challenges by implementing a structured approach to Linux server deployment, security, automation, monitoring, and maintenance.

## Project Objectives

- Deploy and configure an Ubuntu Linux server on AWS EC2.
- Implement secure SSH access and Linux user management.
- Configure firewall rules and server security controls.
- Automate administrative tasks using Bash.
- Manage server configurations using Ansible.
- Deploy and manage services using Nginx and systemd.
- Implement server monitoring and alerting.
- Document troubleshooting, backup, and incident response procedures.

## Technology Stack

- Operating System: Ubuntu Server 24.04 LTS
- Cloud Platform: Amazon Web Services (AWS)
- Compute: Amazon EC2
- Storage: Amazon EBS
- Automation: Ansible
- Scripting: Bash
- Web Server: Nginx
- Monitoring: Prometheus and Grafana (planned)
- Version Control: Git and GitHub
  

## Architecture Overview

The project uses a local Linux workstation as the administration controller and an AWS EC2 Ubuntu server as the managed Linux environment.

The local workstation will be used for:

- Git version control.
- Ansible automation.
- SSH administration.
- Project documentation. 


The AWS EC2 instance will host the Linux services, administrative scripts, and monitoring components. 
```
+----------------------------------+          SSH (Port 22) / Ansible
|     Administration Controller    | ------------------------------------+
|  - Ubuntu Workstation            |                                     |
|  - Git / Ansible / Bash Scripts  |                                     v
+----------------------------------+                   +----------------------------------+
|           AWS EC2 Node           |
|  - Ubuntu 24.04 LTS (t3.micro)   |
|  - Security Hardened (sshd/ufw)  |
|  - Nginx Reverse Proxy           |
|  - EBS Storage / Automated Backup|
+----------------------------------+
```


## Repository Structure

```
enterprise-linux-server-deployment/
├── README.md
├── docs/
│ ├── problem-statement.md
│ ├── architecture.md
│ ├── server-assessment.md
│ ├── deployment-guide.md
│ ├── security-hardening.md
│ ├── troubleshooting.md
│ ├── incident-response.md
│ └── decommissioning-guide.md
├── scripts/
│ ├── system-health-check.sh
│ ├── disk-monitor.sh
│ ├── backup.sh
│ └── user-management.sh
├── ansible/
│ ├── inventory/
│ ├── playbooks/
│ ├── roles/
│ └── group_vars/
├── monitoring/
│ ├── prometheus/
│ └── grafana/
├── security/
│ └── ssh-hardening.conf.example
└── screenshots/
```

## Prerequisites

The following tools and resources are required before installation:

### Infrastructure Requirements

- An AWS account with sufficient available credits or an approved budget.
- An AWS EC2 instance running Ubuntu Server 24.04 LTS.
- An appropriate EC2 instance type and storage capacity.
- An SSH key pair for secure server access.
- A security group with appropriately restricted inbound access.
- A local Linux workstation for administration. 


### Software Requirements

- Git.
- OpenSSH client.
- Bash.
- Python 3.
- Ansible.
- A web browser for AWS management. 


Additional software such as Nginx, Prometheus, and Grafana will be installed during the relevant implementation phases.


## Requirements Before Installation


Before starting the implementation:


- Verify access to the AWS Management Console.
- Confirm the selected AWS region.
- Verify the EC2 instance configuration.
- Confirm SSH or Systems Manager connectivity.
- Ensure the local administration workstation is ready.
- Confirm sufficient disk space and memory.
- Review expected AWS costs.
- Securely store SSH private keys and sensitive credentials. 


## Installation and Setup


The installation process will follow these steps:

- Prepare the local Linux administration workstation.
- Provision the Ubuntu EC2 instance.
- Establish secure remote access.
- Update system packages.
- Configure Linux users and permissions.
- Configure SSH and firewall security.
- Install and configure required administrative tools.
- Deploy Bash automation scripts.
- Configure Ansible management.
- Install and configure monitoring components. 

Detailed commands and implementation evidence will be documented in "docs/deployment-guide.md".

**Status:** In Progress.

## Configuration


Configuration covers the settings required to manage the server and its services.


Examples include:

- SSH daemon configuration.
- Firewall rules.
- Linux user and group permissions.
- Nginx configuration.
- systemd service configuration.
- Ansible inventory and playbook variables.
- Prometheus scrape configuration.
- Grafana dashboard settings. 


Environment-specific values should be stored separately from application and infrastructure code.


Sensitive information such as passwords, private keys, access tokens, and credentials must never be committed to GitHub.


Example environment configuration:

```bash
SERVER_HOST=

SERVER_USER=ubuntu

SSH_KEY_PATH=
```

These are illustrative placeholders, not real credentials.


## Deployment

The infrastructure will be deployed on AWS EC2.

Deployment activities include:

- Provisioning the Linux server.
- Configuring the operating system.
- Applying security controls.
- Deploying administrative scripts.
- Applying Ansible configurations.
- Deploying and managing server services.
- Configuring monitoring and alerting. 


The deployment process and verified results will be recorded in the deployment guide.


**Status: In Progress.**


## Testing and Verification


Testing will be performed throughout the implementation to confirm that configurations and services work as expected.


Planned verification activities include:


|Test| Verification Method|
|-----|----------------|
|OS information| "cat /etc/os-release"
|Kernel version| "uname -r"
|Disk capacity| "df -h"
|Memory usage| "free -h"
|SSH service| "systemctl status ssh"
|Firewall| "sudo ufw status verbose"
|Nginx service| "systemctl status nginx"
|Network connectivity| "ping" and "curl"
|Ansible connectivity| "ansible all -m ping"
|Monitoring| Prometheus targets and Grafana dashboards


Actual test results and evidence will be added after implementation.


## Security Implementation

Security is an important part of this project.

The following measures are planned:

- SSH key-based authentication.
- Restricted SSH network access.
- Linux user and privilege management.
- Least-privilege access controls.
- UFW firewall configuration.
- Secure file and directory permissions.
- Regular security updates.
- Protection of sensitive configuration data.
- Monitoring of system logs and authentication activity. 

Security configurations will be tested before being considered complete.


## Troubleshooting

This section documents common operational problems, their causes, investigation procedures, and resolutions.


Examples of issues to be documented include:

- SSH connection failures.
- Permission denied errors.
- Nginx service failures.
- Disk space exhaustion.
- High memory utilization.
- Firewall connectivity problems.
- Ansible connection failures.
- Monitoring service failures. 


Troubleshooting records will include commands, observations, root causes, corrective actions, and verification results.


See "docs/troubleshooting.md" for detailed procedures.


## Lessons Learned


This section will capture practical knowledge gained during implementation.


Expected learning areas include:


- Linux server administration and troubleshooting.
- Understanding Linux processes and system services.
- SSH security and access control.
- Resource monitoring and capacity management.
- Bash scripting and automation.
- Ansible configuration management.
- AWS EC2 and EBS administration.
- Monitoring and incident investigation.
- Infrastructure cost management.
- Technical documentation and operational procedures. 

Actual lessons will be updated as the project progresses.


##  Future Improvements

Potential enhancements include:

- Multi-server administration using Ansible.
- Automated backup scheduling.
- Centralized log management.
- Advanced monitoring and alerting.
- Automated patch management.
- CI/CD integration.
- Infrastructure provisioning using Terraform.
- AWS Systems Manager integration.
- Disaster recovery procedures.
- Automated compliance and security checks. 


## Author

Linux System Administrator | DevOps Engineer
GitHub: "tobilee10" (https://github.com/tobilee10)


## License

A license will be selected before public distribution.

Until a license is added to the repository, all rights are reserved by the copyright holder. No permissions beyond those provided by applicable law are granted.

See the "LICENSE" file once it is added.

---

**Project Status: In Progress**

This project is being developed as a practical demonstration of Linux System Administration, Cloud Infrastructure Management, Automation, Security, and DevOps Engineering. 