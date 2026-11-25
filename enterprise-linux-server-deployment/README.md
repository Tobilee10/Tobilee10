# Enterprise Linux Server Deployment, Hardening & Monitoring

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-EC2-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-Automation-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Containerization-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-Visualization-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Status](https://img.shields.io/badge/Project-In_Progress-yellow?style=for-the-badge)

## 1. Project Overview

The Enterprise Linux Server Deployment project demonstrates the deployment, administration, security hardening, automation, and monitoring of an Ubuntu Linux server hosted on Amazon Web Services (AWS).

The project applies practical Linux System Administration and DevOps engineering practices to establish a manageable and observable server environment.

It combines:

- AWS EC2 infrastructure.
- Ubuntu Linux server administration.
- SSH security and access management.
- Linux firewall configuration.
- Bash administrative automation.
- Ansible configuration management.
- Docker-based monitoring infrastructure.
- Prometheus metrics collection.
- Grafana dashboards and visualization.
- Alertmanager email notifications.

The objective is to demonstrate how a Linux server can be deployed, secured, automated, monitored, and maintained using practical operational workflows.

## 2. Problem Statement

Organizations depend on Linux servers to host applications, manage services, store data, and support business operations.

Poor server configuration, weak access controls, inadequate monitoring, manual administration, and insufficient backup procedures can result in:

- Security vulnerabilities.
- Service interruptions.
- Resource exhaustion.
- Configuration drift.
- Operational inefficiencies.
- Difficult troubleshooting and incident investigation.

This project addresses these challenges through structured Linux administration, security hardening, automation, infrastructure monitoring, and operational documentation.

## 3. Project Objectives

- Deploy and configure an Ubuntu Linux server on AWS EC2.
- Implement secure SSH access and Linux user management.
- Configure firewall rules and server security controls.
- Automate administrative tasks using Bash.
- Manage server configurations using Ansible.
- Deploy and manage services using Nginx and systemd.
- Implement infrastructure monitoring and alerting.
- Visualize server performance using Grafana.
- Configure automated email notifications through Alertmanager.
- Document deployment, troubleshooting, backup, and incident response procedures.

## 4. Technology Stack

| Category | Technologies |
| :--- | :--- |
| Cloud Platform | Amazon Web Services |
| Compute | AWS EC2 |
| Operating System | Ubuntu Server 24.04 LTS |
| Storage | Amazon EBS |
| Configuration Management | Ansible |
| Scripting | Bash |
| Web Server | Nginx |
| Containerization | Docker, Docker Compose |
| Metrics Collection | Prometheus |
| Metrics Exporter | Node Exporter |
| Visualization | Grafana |
| Alert Management | Alertmanager |
| Notifications | Gmail SMTP |
| Version Control | Git, GitHub |

## 5. Architecture Overview

The project uses a local Linux workstation as the administration and monitoring environment and an AWS EC2 Ubuntu server as the managed Linux environment.

### 5.1 Administration and Monitoring Workstation

The local workstation provides:

- Git version control.
- Ansible automation.
- SSH administration.
- Bash scripting and development.
- Docker and Docker Compose.
- Prometheus metrics collection.
- Grafana dashboards.
- Alertmanager notification management.

### 5.2 AWS EC2 Managed Server

The AWS EC2 instance provides:

- Ubuntu Server 24.04 LTS.
- Linux user and permission management.
- SSH access and security hardening.
- UFW firewall configuration.
- Nginx web server.
- systemd service management.
- Administrative scripts.
- Node Exporter infrastructure metrics.

### 5.3 Monitoring Architecture

The monitoring infrastructure uses a distributed architecture.

```text
              LOCAL LINUX WORKSTATION
       +-----------------------------------+
       |                                   |
       |          Docker Compose           |
       |                                   |
       |  +-------------+                  |
       |  | Prometheus  |<----------+      |
       |  +------+------+           |      |
       |         |                  |      |
       |         |                  |      |
       |         v                  |      |
       |  +-------------+           |      |
       |  |  Grafana    |           |      |
       |  +-------------+           |      |
       |                            |      |
       |  +-------------+           |      |
       |  | Alertmanager|           |      |
       |  +------+------+           |      |
       +---------|------------------|------+
                 |                  |
                 | SMTP             | TCP 9100
                 v                  |
           Gmail SMTP               |
                                    |
                                    v
                         +----------------------+
                         | AWS EC2 Ubuntu Server|
                         |                      |
                         |  Node Exporter       |
                         |  Port 9100           |
                         |                      |
                         |  Linux Metrics       |
                         |  CPU                 |
                         |  Memory              |
                         |  Disk                |
                         |  Network             |
                         |  Uptime              |
                         +----------------------+
```

### 5.4 Monitoring Data Flow

1. Node Exporter runs as a systemd service on the AWS EC2 server.
2. Node Exporter exposes Linux system metrics on TCP port 9100.
3. Prometheus scrapes the metrics from the EC2 server.
4. Prometheus stores and evaluates the collected metrics.
5. Grafana queries Prometheus and displays monitoring dashboards.
6. Prometheus sends firing alerts to Alertmanager.
7. Alertmanager routes notifications through Gmail SMTP.

Important architecture note: Prometheus, Grafana, and Alertmanager currently run on the local workstation. The workstation must remain powered on and connected for continuous monitoring and email notifications.

## 6. Implemented Features

### 6.1 Linux Server Administration

The project includes practical Linux administration activities such as:

- System information and resource inspection.
- Linux user and group management.
- File and directory permissions.
- SSH administration.
- Service management with systemd.
- Disk and storage management.
- System logging and log rotation.

### 6.2 Security Hardening

Security controls include:

- SSH access hardening.
- Dedicated service accounts.
- Linux permissions and access controls.
- UFW firewall configuration.
- systemd service restrictions.
- Restricted network access to monitoring services.
- Sensitive credential exclusion from Git.

### 6.3 Bash Automation

Administrative scripts support routine server management.

The project includes scripts for:

- System health checks.
- Disk monitoring.
- Automated backups.
- User management.

### 6.4 Ansible Automation

Ansible is used to manage server configuration and automate administrative operations.

The project includes:

- Ansible inventory.
- Playbooks.
- Roles.
- Group variables.
- Remote server configuration management.

### 6.5 Infrastructure Monitoring

The monitoring implementation includes:

| Component | Function |
| :--- | :--- |
| Node Exporter | Exposes Linux host metrics |
| Prometheus | Collects and stores metrics |
| Grafana | Visualizes server performance |
| Alertmanager | Routes and manages alerts |
| Gmail SMTP | Delivers email notifications |
| Docker Compose | Manages monitoring containers |

The monitoring dashboard covers:

- CPU utilization.
- Memory utilization.
- Disk utilization.
- Available disk space.
- Network receive and transmit traffic.
- Server uptime.

The alerting implementation includes resource utilization, network traffic, and monitoring-target availability conditions.

## 7. Repository Structure

```text
enterprise-linux-server-deployment/
│
├── README.md
│
├── docs/
│   ├── problem-statement.md
│   ├── architecture.md
│   ├── server-assessment.md
│   ├── deployment-guide.md
│   ├── security-hardening.md
│   ├── troubleshooting.md
│   ├── incident-response.md
│   ├── decommissioning-guide.md
│   │
│   └── monitoring/
│       ├── README.md
│       ├── architecture.md
│       ├── deployment-guide.md
│       ├── troubleshooting.md
│       ├── prometheus-configuration.md
│       ├── grafana-dashboard.md
│       ├── alerting-and-notifications.md
│       └── security.md
│
├── scripts/
│   ├── system-health-check.sh
│   ├── disk-monitor.sh
│   ├── backup.sh
│   └── user-management.sh
│
├── ansible/
│   ├── inventory/
│   ├── playbooks/
│   ├── roles/
│   └── group_vars/
│
├── monitoring/
│   ├── docker-compose.yml
│   ├── prometheus/
│   │   ├── prometheus.yml
│   │   └── alerts/
│   │       ├── availability-alerts.yml
│   │       ├── cpu-alerts.yml
│   │       ├── disk-alerts.yml
│   │       ├── memory-alerts.yml
│   │       ├── network-alerts.yml
│   │       └── prometheus-alerts.yml
│   │
│   ├── alertmanager/
│   │   ├── alertmanager.yml
│   │   └── secrets/
│   │
│   └── grafana/
│       └── .env
│
├── security/
│   └── ssh-hardening.conf.example
│
└── screenshots/
```

Sensitive files and credentials are excluded from version control.

## 8. Prerequisites

### Infrastructure Requirements

- AWS account with an approved budget.
- AWS EC2 Ubuntu Server 24.04 LTS.
- Appropriate EC2 instance type and storage.
- SSH key pair.
- Security group with restricted inbound access.
- Local Linux administration workstation.

### Software Requirements

- Git.
- OpenSSH client.
- Bash.
- Python 3.
- Ansible.
- Docker.
- Docker Compose.
- Web browser.

## 9. Deployment and Configuration

The implementation follows a structured deployment process:

1. Prepare the local Linux administration workstation.
2. Provision the Ubuntu EC2 instance.
3. Establish secure remote access.
4. Update and configure the operating system.
5. Configure Linux users and permissions.
6. Apply SSH and firewall security.
7. Deploy administrative Bash scripts.
8. Configure Ansible automation.
9. Deploy and manage server services.
10. Install Node Exporter on the managed server.
11. Deploy Prometheus, Grafana, and Alertmanager using Docker Compose.
12. Configure dashboards and alert notifications.
13. Validate monitoring functionality and document results.

Refer to the project documentation for detailed implementation procedures.

## 10. Monitoring Access and Network Security

The monitoring web interfaces are bound to the local workstation's loopback interface.

| Service | Local Port |
| :--- | :--- |
| Prometheus | 9090 |
| Grafana | 3000 |
| Alertmanager | 9093 |

Node Exporter listens on TCP port 9100 on the managed EC2 server.

Its inbound access should be restricted to the trusted monitoring workstation's public IP address using a "/32" source CIDR.

The monitoring web interfaces should not be exposed directly to the public internet.

## 11. Testing and Verification

Testing is performed throughout implementation.

| Component | Verification |
| :--- | :--- |
| Operating system | "cat /etc/os-release" |
| Kernel | "uname -r" |
| Disk capacity | "df -h" |
| Memory | "free -h" |
| SSH | "systemctl status ssh" |
| Firewall | "sudo ufw status verbose" |
| Nginx | "systemctl status nginx" |
| Network connectivity | "ping", "curl" |
| Ansible | "ansible all -m ping" |
| Docker containers | "docker compose ps" |
| Prometheus | Prometheus targets and rules pages |
| Node Exporter | "curl http://localhost:9100/metrics" on the managed server |
| Grafana | Dashboard and datasource validation |
| Alertmanager | Configuration and routing validation |

Actual results and implementation evidence are maintained through project documentation and screenshots.

## 12. Documentation

Detailed technical documentation is available in the "docs/" directory.

### General Server Documentation

Covers:

- Project architecture.
- Server assessment.
- Deployment.
- Security hardening.
- Troubleshooting.
- Incident response.
- Decommissioning.

### Monitoring Documentation

The "docs/monitoring/" directory contains:

- Monitoring architecture.
- Deployment guide.
- Prometheus configuration.
- Grafana dashboard documentation.
- Alerting and notification configuration.
- Monitoring security.
- Troubleshooting procedures.

## 13. Lessons Learned

This project provides practical experience in:

- Linux server administration.
- SSH security and access management.
- Linux processes and system services.
- Bash scripting and automation.
- Ansible configuration management.
- AWS EC2 administration.
- Docker and container orchestration.
- Prometheus metrics collection.
- PromQL query development.
- Grafana dashboard creation.
- Alertmanager notification routing.
- Infrastructure monitoring and troubleshooting.
- Technical documentation.
- Infrastructure security and cost awareness.

## 14. Future Improvements

Potential enhancements include:

- Multi-server administration using Ansible.
- Terraform infrastructure provisioning.
- Automated patch management.
- Centralized log management.
- Application-level monitoring.
- Dedicated remote monitoring infrastructure.
- External monitoring of the monitoring system.
- Automated dashboard provisioning.
- CI/CD integration.
- AWS Systems Manager integration.
- Disaster recovery and backup automation.
- Automated compliance and security checks.

## 15. Author

Linux System Administrator | DevOps Engineer

GitHub: "tobilee10" (https://github.com/tobilee10)

## 16. License

A license will be selected before public distribution.

Until a license is added to the repository, all rights are reserved by the copyright holder. No permissions beyond those provided by applicable law are granted.

See the "LICENSE" file once it is added.

---

Project Status: In Progress

This project is an ongoing practical demonstration of Linux System Administration, Cloud Infrastructure Management, Automation, Security Engineering, and DevOps practices.