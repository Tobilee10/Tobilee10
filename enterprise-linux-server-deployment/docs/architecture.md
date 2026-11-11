# Enterprise Linux Server Deployment: Architecture

## Introduction

This document describes the proposed architecture for the Enterprise Linux Server Deployment project.

The project focuses on deploying, securing, managing, monitoring, and maintaining an Ubuntu Linux server hosted on Amazon Web Services (AWS).

The architecture combines AWS infrastructure, Linux system administration, automation, security hardening, monitoring, and operational documentation.

**Project Status: Architecture Planning**

## Architecture Objectives

The architecture is designed to:

- Deploy an Ubuntu Linux server on AWS EC2.
- Provide secure administrative access.
- Apply Linux security hardening practices.
- Automate routine administrative tasks.
- Configure and manage system services.
- Monitor server health and resource utilization.
- Implement backup and recovery procedures.
- Document operational and troubleshooting procedures.

## High-Level Architecture

The proposed architecture consists of the following components:

- Local Linux workstation – Ansible control node and administrative workstation.
- AWS VPC – Network environment for the server.
- Public subnet – Hosts the EC2 instance with controlled administrative access.
- Security Group – Controls inbound and outbound network traffic.
- Amazon EC2 – Hosts the Ubuntu Linux server.
- Amazon EBS – Provides persistent block storage.
- SSH and AWS Systems Manager (SSM) – Administrative access methods.
- Ansible and Bash – Configuration management and task automation.
- Nginx and systemd – Web server and service management.
- Prometheus and Grafana – Planned monitoring and visualization components.

## Architecture Diagram

flowchart TB
    A[Administrator]
    B[Local Linux Workstation]
    C[Ansible Control Node]
    D[AWS Cloud]
    E[VPC]
    F[Public Subnet]
    G[Security Group]
    H[EC2 Ubuntu Linux Server]
    I[Amazon EBS Storage]
    J[SSH / AWS Systems Manager]
    K[Nginx and systemd]
    L[Bash Scripts]
    M[Prometheus]
    N[Grafana]

    A --> B
    B --> C
    B --> J
    J --> G
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    H --> K
    H --> L
    H --> M
    M --> N

Note: This is a logical representation of the proposed design, not a record of deployed resources.

## Infrastructure Components

### AWS VPC

The VPC provides an isolated networking environment for the Linux server.

### Public Subnet

The EC2 instance will initially be deployed in a public subnet to support controlled administrative access.

### Security Group

The security group will enforce network access restrictions.

Planned rules:

|Protocol| Port| Purpose|
|---------|-----|--------|
|TCP| 22| SSH administrative access, restricted to an approved source IP
|TCP| 80| HTTP access if the Nginx web server is exposed
|TCP| 443| HTTPS access if TLS is configured

Monitoring interfaces will not be exposed publicly by default.

### Amazon EC2

The EC2 instance will host Ubuntu Server and serve as the main Linux administration environment.

Planned configuration:

- Operating System: Ubuntu Server 24.04 LTS
- Instance Type: t3.medium
- vCPUs: 2
- Memory: 4 GiB
- Storage: 30 GiB encrypted gp3 EBS volume

The final configuration will be documented after instance provisioning.

### Amazon EBS

EBS will provide persistent storage for the operating system, application files, logs, and other server data.

## Access and Administration

Administrative access will be provided through:

- SSH using a dedicated private key.
- AWS Systems Manager Session Manager where configured and supported.

SSH access will be restricted to approved sources. Private keys and credentials must never be committed to the Git repository.

## Automation and Configuration Management

**Bash**

Bash scripts will automate routine administration, including:

- Server health checks.
- Disk usage monitoring.
- Backup operations.
- User management tasks.


**Ansible**

Ansible will be used from the local Linux workstation to manage the EC2 server.

Planned tasks include:

- Package installation and updates.
- User and group management.
- SSH configuration.
- Firewall configuration.
- Nginx installation and configuration.
- Service management.
- Reusable configuration through Ansible roles.

## Web and Service Management

**Nginx**

Nginx will be used to demonstrate Linux web server installation, configuration, and management.

**systemd**

systemd will manage Linux services and support service startup, restart policies, and operational troubleshooting.

## Monitoring Architecture

The project plans to introduce:

- Prometheus for metrics collection.
- Grafana for dashboards and visualization.
- Linux system metrics such as CPU, memory, disk, and network utilization.

Monitoring deployment will be selected based on available server resources and cost considerations.

Monitoring interfaces will remain private or locally accessible unless secure remote access is deliberately configured.

## Security Architecture

Security controls will include:

- SSH hardening.
- Restricted administrative access.
- Least-privilege user permissions.
- Firewall configuration.
- Regular security updates.
- Encrypted EBS storage.
- Secure handling of credentials.
- Service and log monitoring.

## Backup and Recovery

Backup procedures will be implemented to demonstrate:

- Backup creation.
- Backup storage and retention.
- Backup verification.
- Recovery testing.

The project will document the difference between file-level backups and AWS EBS snapshots.

## Deployment Workflow

The planned deployment sequence is:

1. Prepare the local Linux workstation.
2. Provision AWS networking and EC2 resources.
3. Establish secure administrative access.
4. Perform initial server assessment.
5. Apply Linux security hardening.
6. Configure system packages and services.
7. Implement Bash automation.
8. Configure Ansible management.
9. Deploy Nginx.
10. Configure monitoring.
11. Implement backup procedures.
12. Perform testing and verification.
13. Document the final deployment.
14. Decommission AWS resources after project completion.

## Cost Considerations

The project will use a limited AWS environment to control expenses.

Cost-control measures include:

- Avoiding unnecessary AWS resources.
- Monitoring instance running time.
- Avoiding unnecessary Elastic IPs, NAT Gateways, and load balancers.
- Reviewing EBS storage and snapshot usage.
- Terminating resources after project completion.

No additional AWS resources should be provisioned without reviewing their expected cost.

## Future Improvements

Potential enhancements include:

- HTTPS with TLS certificates.
- Centralized log management.
- CloudWatch dashboards and alarms.
- Automated configuration validation.
- More advanced backup and recovery.
- Infrastructure provisioning with Terraform.
- CI/CD integration for configuration changes.

## Conclusion

This architecture provides a practical foundation for demonstrating Linux server administration and DevOps operational skills.

It combines AWS infrastructure, Linux security, configuration management, automation, monitoring, backup, and documentation into one structured portfolio project.

The architecture will be updated as implementation progresses so that the documentation accurately reflects the deployed environment.