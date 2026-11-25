# Monitoring System Architecture

## 1. Introduction

This document describes the architecture of the monitoring and alerting solution implemented as part of the `enterprise-linux-server-deployment` project.

The solution monitors an Ubuntu Linux server hosted on AWS EC2 using **Prometheus**, **Node Exporter**, **Grafana**, and **Alertmanager**. The monitoring stack runs in Docker containers on a separate local Linux workstation, while Node Exporter runs directly on the managed EC2 server as a `systemd` service.

The architecture provides infrastructure metrics collection, visualization, alert evaluation, and email notifications.

## 2. Architecture Overview

The architecture consists of two primary environments:

### Managed Server — AWS EC2

The EC2 Ubuntu server is the infrastructure being monitored:

* **Operating System:** Ubuntu Linux.

* **Metrics Agent:** Node Exporter installed directly on the host.

* **Service Management:** `systemd` manages the Node Exporter service.

* **Endpoint:** Exposes host-level metrics on TCP port `9100`.

### Monitoring Server — Local Linux Workstation

The local Linux workstation hosts the monitoring stack using Docker Compose:

* **Prometheus:** Collects and stores time-series metrics and evaluates alert rules.

* **Grafana:** Visualizes metrics through dashboards.

* **Alertmanager:** Groups, routes, and delivers alert notifications.

* **Docker Compose:** Manages the monitoring containers, networks, volumes, and configuration mounts.

*(See [Section 10](#10-availability-and-operational-dependencies) for workstation uptime and connectivity dependencies.)*

## 3. High-Level Architecture Diagram

```
flowchart TB
    subgraph AWS["AWS Cloud"]
        EC2["EC2 Ubuntu Managed Server"]
        SYSTEMD["systemd Service"]
        NE["Node Exporter :9100"]

        EC2 --> SYSTEMD
        SYSTEMD --> NE
    end

    subgraph LOCAL["Local Linux Monitoring Workstation"]
        subgraph DOCKER["Docker Compose Environment"]
            PROM["Prometheus :9090"]
            GRAF["Grafana :3000"]
            AM["Alertmanager :9093"]
        end
    end

    NE -->|"Host metrics over TCP 9100"| PROM
    PROM -->|"PromQL queries"| GRAF
    PROM -->|"Firing and resolved alerts"| AM
    AM -->|"Email notifications via SMTP"| EMAIL["Email Inbox"]

    ADMIN["Administrator"] --> GRAF
    ADMIN --> PROM
    ADMIN --> AM

```

## 4. Component Responsibilities

### 4.1 Node Exporter

Node Exporter runs directly on the managed Ubuntu server to collect and expose operating-system-level metrics, including:

* CPU time and utilization-related metrics.

* Total and available memory.

* Filesystem capacity and available disk space.

* Network bytes received and transmitted.

* System boot time.

Node Exporter exposes these metrics at `http://EC2_PUBLIC_IP:9100/metrics`. It uses a pull model—it does not push metrics to Prometheus; instead, Prometheus periodically scrapes the endpoint.

### 4.2 Prometheus

Prometheus is the central metrics collection and monitoring engine. Its responsibilities include:

1. Scraping Node Exporter every `15s`.

2. Collecting its own internal metrics.

3. Storing time-series data.

4. Evaluating alert rules.

5. Forwarding firing and resolved alerts to Alertmanager via Docker's internal DNS (`alertmanager:9093`).

### 4.3 Grafana

Grafana provides the visualization layer. It queries Prometheus (`http://prometheus:9090`) using PromQL and presents the collected metrics in dashboards without interacting directly with Node Exporter.

The project dashboard, **Enterprise Linux Server Monitoring**, tracks six areas:

1. **CPU Utilization**

2. **Memory Utilization**

3. **Disk Utilization**

4. **Disk Available**

5. **Network Traffic**

6. **Server Uptime**

### 4.4 Alertmanager

Alertmanager receives alerts from Prometheus and manages notification delivery:

* Grouping related alerts.

* Routing alerts according to severity.

* Controlling notification wait and repeat timing.

* Sending firing and resolved email notifications via Gmail SMTP.

Alertmanager reads the SMTP password from a mounted secret file rather than storing credentials inline in its main configuration.

### 4.5 Docker Compose

Docker Compose manages the **Prometheus**, **Grafana**, and **Alertmanager** services, providing:

* Container lifecycle management and service dependencies.

* Configuration and read-only secret mounts.

* Persistent storage via named Docker volumes (`prometheus_data`, `alertmanager_data`, and `grafana_data`).

* Container health checks.

## 5. Metrics Collection Flow

```
Node Exporter (:9100) ──[HTTP Scrape / 15s]──> Prometheus (:9090) ──[PromQL]──> Grafana (:3000)

```

1. **Expose:** Node Exporter collects OS metrics from the EC2 host and exposes them over HTTP on port `9100`.

2. **Scrape & Store:** Prometheus connects to the endpoint every `15s` and stores the metrics as time-series data.

3. **Visualize:** Grafana queries Prometheus when a dashboard is opened or refreshed and renders the results in panels.

> **Architectural Separation:** Node Exporter *exposes* metrics, Prometheus *collects and stores* them, and Grafana *queries and visualizes* them.

## 6. Alerting and Notification Flow

The alerting pipeline operates independently of Grafana dashboard sessions:

```
Prometheus Rule Evaluation ──[Firing]──> Alertmanager ──[SMTP]──> Email Inbox
                                              │
Prometheus Rule Evaluation ──[Resolved]───────┘

```

1. Prometheus evaluates configured alert rules against collected metrics.

2. When a condition remains true for its configured duration, the alert transitions from `Pending` to `Firing`.

3. Prometheus forwards the firing alert to Alertmanager.

4. Alertmanager groups and routes the alert, then sends an email notification through Gmail SMTP.

5. Once the condition clears, Prometheus resolves the alert and Alertmanager sends a recovery email (`send_resolved: true`).

### Alert Severity Routing

Both routes currently target the same email receiver, differing only in notification timing:

| Severity | Notification Behavior | 
| ----- | ----- | 
| **Critical** | Shorter initial group wait and repeat intervals | 
| **Warning** | Longer initial group wait and repeat intervals | 

## 7. Network Architecture and Communication

The monitoring stack uses external, internal Docker, and local loopback communication paths:

### 7.1 External Monitoring Traffic (Workstation to AWS EC2)

| Source | Destination | Protocol / Scheme | Port | Purpose | 
| ----- | ----- | ----- | ----- | ----- | 
| Local workstation | EC2 managed server | `TCP` (`HTTP`) | `9100` | Prometheus metrics scraping | 
| Alertmanager container | Gmail SMTP server | `TCP` (`SMTP/TLS`) | `587` | Outbound alert email delivery | 

The EC2 security group restricts inbound TCP port `9100` to the trusted workstation's public IP address using a `/32` CIDR block. Port `9100` is never exposed to the public internet.

### 7.2 Internal Docker Network Communication

Containers communicate across Docker's internal bridge network using service-name DNS resolution:

| Source | Destination | Protocol / Scheme | Port | Purpose | 
| ----- | ----- | ----- | ----- | ----- | 
| Prometheus | Alertmanager (`alertmanager:9093`) | `TCP` (`HTTP`) | `9093` | Alert delivery | 
| Grafana | Prometheus (`http://prometheus:9090`) | `TCP` (`HTTP`) | `9090` | PromQL metrics queries | 

### 7.3 Administrator Web Access

All web interfaces are bound strictly to the local loopback interface (`127.0.0.1`) so they are not exposed on external network interfaces:

| Service | Local URL | Protocol / Scheme | Host Binding | Purpose | 
| ----- | ----- | ----- | ----- | ----- | 
| **Prometheus** | `http://localhost:9090` | `TCP` (`HTTP`) | `127.0.0.1:9090` | Metrics explorer, targets, and alert status | 
| **Grafana** | `http://localhost:3000` | `TCP` (`HTTP`) | `127.0.0.1:3000` | Monitoring dashboards | 
| **Alertmanager** | `http://localhost:9093` | `TCP` (`HTTP`) | `127.0.0.1:9093` | Active alerts and silence management | 

For remote administration, use an encrypted tunnel such as an SSH tunnel or VPN.

## 8. Persistent Storage Architecture

The monitoring stack uses named Docker volumes to retain state across container recreations:

| Volume | Purpose | 
| ----- | ----- | 
| `prometheus_data` | Prometheus time-series database (TSDB) | 
| `alertmanager_data` | Alertmanager notification log and silence state | 
| `grafana_data` | Grafana dashboards, data sources, and user settings | 

> **Backup Note:** Docker volumes preserve data across container restarts, but they do not replace off-host backups. Critical configurations and data should be backed up separately.

## 9. Security Architecture

### Managed Server (EC2)

* Node Exporter runs under a dedicated non-login Linux user (`node_exporter`).

* Service execution is hardened with `systemd` security restrictions to minimize privileges.

* EC2 Security Group rules restrict inbound TCP `9100` to the trusted workstation's `/32` IP.

### Monitoring Workstation & Credential Management

* Container host ports bind exclusively to `127.0.0.1` (see [Section 7.3](#73-administrator-web-access)).

* SMTP credentials are isolated in a mounted secret file outside the main Alertmanager configuration.

* Sensitive files—including Grafana `.env` files and SMTP password files—are excluded from Git via `.gitignore`, with placeholder `.example` files committed instead.

## 10. Availability and Operational Dependencies

Because the monitoring stack runs on a local workstation, continuous monitoring depends on:

* The workstation remaining powered on with active network connectivity to AWS.

* The Docker daemon running and all three monitoring containers remaining healthy.

* The EC2 instance and Node Exporter service remaining reachable.

If the workstation shuts down or loses connectivity, Prometheus cannot scrape metrics or evaluate alerts until connectivity is restored.

## 11. Architecture Limitations

This implementation is designed as a practical monitoring lab and portfolio architecture rather than a highly available production platform:

1. **Single-node workstation dependency:** Monitoring availability is tied to a single local machine's uptime and network connection.

2. **Local TSDB storage:** Prometheus uses local volume storage rather than a distributed, long-term metrics backend.

3. **Single notification channel:** Alert delivery relies solely on email via Gmail SMTP.

4. **No external dead-man's-switch:** While Prometheus can alert when its own scrape target fails *while the Prometheus process is running*, it cannot evaluate rules or send alerts if the Prometheus process or host workstation goes down entirely.

## 12. Future Architecture Improvements

* Deploy Prometheus, Grafana, and Alertmanager on a dedicated, always-on monitoring host or managed platform.

* Add an independent external availability check (dead-man's-switch) to monitor the monitoring stack itself.

* Automate backups for `prometheus_data` and `grafana_data`.

* Enable TLS and centralized authentication (e.g., reverse proxy with SSO/OIDC) for remote web access.

* Integrate remote write / long-term metrics storage (e.g., Thanos or VictoriaMetrics).

* Expand coverage to application-level metrics and centralized log aggregation (e.g., Grafana Loki).

* Provision the monitoring stack and firewall rules using Infrastructure as Code (Terraform / Ansible).

## 13. Conclusion

This architecture demonstrates an end-to-end, open-source infrastructure monitoring solution combining host-level metrics collection with containerized visualization and alerting. It reflects practical implementation across Linux `systemd` hardening, AWS Security Group network isolation, Docker Compose orchestration, PromQL querying, and secret-safe alert routing.