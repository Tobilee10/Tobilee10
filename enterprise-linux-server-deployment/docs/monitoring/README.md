# Monitoring and Observability

**Enterprise Linux Server Deployment**

## 1. Overview

This document describes the monitoring and observability implementation of the **Enterprise Linux Server Deployment** project.

The monitoring solution was implemented to provide visibility into the health, performance, availability, and operational status of the managed Linux server.

### Technology Stack

* **Prometheus:** Metrics collection, storage, and alert evaluation.

* **Node Exporter:** Exposing Linux host metrics.

* **Grafana:** Metrics visualization and dashboard management.

* **Alertmanager:** Alert grouping, routing, and notification management.

* **Gmail SMTP:** Email notifications.

* **Docker Compose:** Managing the monitoring services.

The monitoring environment runs on a local Linux workstation using Docker Compose, while Node Exporter runs as a `systemd` service on the AWS EC2 managed server.

The implementation includes infrastructure monitoring, alert testing, recovery notifications, container health checks, and configuration security.

## 2. Monitoring Objectives

The objectives of this implementation are:

 1. Monitor CPU utilization.

 2. Monitor memory utilization and available memory.

 3. Monitor filesystem utilization and available disk space.

 4. Monitor incoming and outgoing network traffic.

 5. Monitor server uptime.

 6. Detect monitoring-agent failures.

 7. Detect missing Prometheus scrape targets.

 8. Monitor Prometheus scrape health.

 9. Generate alerts when defined thresholds are exceeded.

10. Deliver firing and resolved notifications through email.

11. Monitor the health of Docker-based monitoring services.

## 3. Architecture

### 3.1 Architecture Overview

The monitoring architecture follows a pull-based metrics collection model.

Node Exporter exposes host metrics over HTTP. Prometheus periodically scrapes the metrics endpoint, stores the collected time-series data, and evaluates alert rules.

Grafana queries Prometheus and displays the metrics through dashboards.

When an alert condition is satisfied, Prometheus forwards the alert to Alertmanager. Alertmanager processes the notification according to its routing configuration and sends email notifications through Gmail SMTP.

### 3.2 Architecture Diagram

```
flowchart TD
    subgraph AWS["AWS Cloud"]
        EC2["Ubuntu EC2 Managed Server"]
        NE["Node Exporter<br/>Systemd Service<br/>Port 9100"]
        EC2 --> NE
    end

    subgraph LOCAL["Local Linux Monitoring Environment"]
        P["Prometheus<br/>Port 9090"]
        G["Grafana<br/>Port 3000"]
        A["Alertmanager<br/>Port 9093"]

        P --> G
        P --> A
    end

    NE -->|"HTTP metrics scrape<br/>TCP 9100"| P
    A -->|"SMTP notifications"| EMAIL["Gmail Inbox"]

    P -->|"Metrics queries"| G

```

### 3.3 Component Responsibilities

| Component | Responsibility | Port | 
| ----- | ----- | ----- | 
| **Node Exporter** | Exposes Linux host metrics | `9100` | 
| **Prometheus** | Scrapes and stores metrics | `9090` | 
| **Grafana** | Visualizes metrics | `3000` | 
| **Alertmanager** | Routes and manages alerts | `9093` | 
| **Gmail SMTP** | Delivers email notifications | `587` | 

### 3.4 Network Architecture

The implementation uses the following connectivity:

* Prometheus communicates with Node Exporter through TCP port `9100`.

* Prometheus communicates with Alertmanager through Docker service discovery at `alertmanager:9093`.

* Grafana communicates with Prometheus through `http://prometheus:9090`.

* Alertmanager communicates with Gmail SMTP through port `587`.

Prometheus, Grafana, and Alertmanager host ports are bound to `localhost` (`127.0.0.1`).

The EC2 security group restricts inbound TCP port `9100` to the trusted monitoring workstation's public IP address using a `/32` source restriction.

> **Security Note:** Port `9100` must never be exposed to the entire internet (`0.0.0.0/0`).

> **Architecture Consideration:** Because Prometheus and Grafana run on the local workstation, the workstation must remain powered on and connected to the internet for continuous monitoring. This implementation is suitable for a portfolio and practical monitoring lab, but it is not a highly available production monitoring platform.

## 4. Node Exporter Installation and Configuration

### 4.1 Purpose

Node Exporter collects Linux system metrics and exposes them through an HTTP metrics endpoint.

It provides information about:

* CPU activity

* Memory utilization

* Filesystem usage

* Network interfaces

* System uptime

* Kernel and operating-system information

Node Exporter version `1.12.1` was deployed on the Ubuntu EC2 managed server.

### 4.2 Service Configuration

Node Exporter was configured to run as a `systemd` service.

A dedicated non-login Linux account named `node_exporter` was created to run the service. This avoids running the monitoring agent with unnecessary `root` privileges. The service was also configured with `systemd` security restrictions.

### 4.3 Service Management

Check service status:

```
sudo systemctl status node_exporter

```

Start the service:

```
sudo systemctl start node_exporter

```

Stop the service:

```
sudo systemctl stop node_exporter

```

Restart the service:

```
sudo systemctl restart node_exporter

```

Enable automatic startup:

```
sudo systemctl enable node_exporter

```

Check listening port:

```
sudo ss -tulnp | grep 9100

```

### 4.4 Verify Metrics Endpoint

From the managed server:

```
curl http://localhost:9100/metrics

```

Expected output includes Prometheus-formatted metrics such as:

```
node_cpu_seconds_total
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes
node_filesystem_size_bytes
node_network_receive_bytes_total
node_network_transmit_bytes_total
node_boot_time_seconds

```

## 5. Prometheus Deployment

### 5.1 Purpose

Prometheus is responsible for:

* Collecting metrics from monitored targets.

* Storing time-series data.

* Evaluating alert rules.

* Exposing a query interface.

* Forwarding alerts to Alertmanager.

Prometheus runs in a Docker container on the local Linux monitoring workstation.

### 5.2 Configuration Location

```
monitoring/
└── prometheus/
    ├── prometheus.yml
    └── alerts/
        ├── system-alerts.yml
        ├── availability-alerts.yml
        └── prometheus-alerts.yml

```

*Note: The alert filenames above represent the logical organization of the rules; retain the actual filenames used in the repository.*

### 5.3 Prometheus Scrape Configuration

The configuration includes:

* Global scrape interval: `15s`

* Global evaluation interval: `15s`

* Prometheus self-monitoring

* EC2 managed-server monitoring

* Alertmanager integration

* Alert rule file discovery

Example `prometheus.yml`:

```
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "/etc/prometheus/alerts/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "alertmanager:9093"

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets:
          - "localhost:9090"

  - job_name: "enterprise-linux-server"
    static_configs:
      - targets:
          - "YOUR_EC2_PUBLIC_IP:9100"

```

*Replace `YOUR_EC2_PUBLIC_IP` with the actual configured target when reproducing the deployment.*

### 5.4 Prometheus Configuration Validation

Validate the configuration:

```
docker exec enterprise-prometheus \
  promtool check config /etc/prometheus/prometheus.yml

```

Validate alert rules:

```
docker exec enterprise-prometheus \
  promtool check rules /etc/prometheus/alerts/availability-alerts.yml

```

Reload Prometheus:

```
docker exec enterprise-prometheus \
  wget -qO- --post-data='' \
  http://localhost:9090/-/reload

```

**Web Interfaces:**

* **Prometheus UI:** `http://localhost:9090`

* **Targets:** `http://localhost:9090/targets`

* **Alerts:** `http://localhost:9090/alerts`

## 6. Grafana Dashboards

### 6.1 Purpose

Grafana provides a visual interface for analyzing the metrics collected by Prometheus.

Grafana runs as a Docker container and uses Prometheus as its data source. The configured data source URL is:

```
http://prometheus:9090

```

### 6.2 Enterprise Linux Server Monitoring Dashboard

A dashboard named **Enterprise Linux Server Monitoring** was created. It contains six monitoring panels:

1. **CPU Utilization**

2. **Memory Utilization**

3. **Disk Utilization**

4. **Disk Available**

5. **Network Traffic**

6. **Server Uptime**

### 6.3 PromQL Queries

**CPU utilization** (percentage of CPU time not spent idle):

```
100 * (
  1 - avg by(instance) (
    rate(node_cpu_seconds_total{mode="idle"}[5m])
  )
)

```

**Memory utilization** (calculated using available memory rather than only free memory):

```
100 * (
  1 - node_memory_MemAvailable_bytes
  /
  node_memory_MemTotal_bytes
)

```

**Available memory:**

```
node_memory_MemAvailable_bytes

```

**Disk utilization:**

```
100 * (
  1 -
  node_filesystem_avail_bytes{
    mountpoint="/",
    fstype!~"tmpfs|overlay|squashfs"
  }
  /
  node_filesystem_size_bytes{
    mountpoint="/",
    fstype!~"tmpfs|overlay|squashfs"
  }
)

```

**Available disk space** (configure the panel unit to `GiB`):

```
node_filesystem_avail_bytes{
  mountpoint="/",
  fstype!~"tmpfs|overlay|squashfs"
}

```

**Incoming network traffic** (bytes per second, excluding loopback):

```
rate(node_network_receive_bytes_total{device!="lo"}[5m])README.md

```

**Outgoing network traffic** (bytes per second, excluding loopback):

```
rate(node_network_transmit_bytes_total{device!="lo"}[5m])

```

**Server uptime:**

```
node_time_seconds - node_boot_time_seconds

```

### 6.4 Dashboard Interpretation

The dashboard allows an administrator to:

* Identify CPU spikes.

* Monitor memory consumption.

* Detect low disk availability.

* Observe incoming and outgoing network traffic.

* Determine how long the server has been running.

Dashboard values should be interpreted in relation to the workload, server capacity, and normal operating baseline.

## 7. Prometheus Alert Rules

### 7.1 Purpose

Prometheus alert rules continuously evaluate defined conditions against collected metrics.

An alert generally moves through the following states:

* **Inactive:** The condition is not currently met.

* **Pending:** The condition is met, but its configured waiting period has not elapsed.

* **Firing:** The condition has remained true for the required duration.

### 7.2 System Resource Alerts

| Alert | Condition | Duration | Severity | 
| ----- | ----- | ----- | ----- | 
| `HighCPUUtilization` | CPU above `85%` | `5m` | Warning | 
| `HighMemoryUtilization` | Memory above `85%` | `5m` | Warning | 
| `HighDiskUtilization` | Disk above `80%` | `5m` | Warning | 
| `HighNetworkReceive` | Incoming traffic above `10 MiB/s` | `5m` | Warning | 
| `HighNetworkTransmit` | Outgoing traffic above `10 MiB/s` | `5m` | Warning | 

*Note: These thresholds are initial monitoring policies for this project, not universal production limits.*

### 7.3 Availability Alerts

| Alert | Purpose | Duration | Severity | 
| ----- | ----- | ----- | ----- | 
| `NodeExporterDown` | Detects an unreachable Node Exporter target | `2m` | Critical | 
| `PrometheusTargetMissing` | Detects when the managed-server target disappears from scrape data | `2m` | Critical | 

**`NodeExporterDown` expression:**

```
up{job="enterprise-linux-server"} == 0

```

**`PrometheusTargetMissing` expression:**

```
absent(up{job="enterprise-linux-server"})

```

The distinction is important: `NodeExporterDown` detects a known but unreachable target, while `PrometheusTargetMissing` detects the absence of the target's time series.

### 7.4 Prometheus Self-Monitoring Alerts

| Alert | Purpose | Duration | Severity | 
| ----- | ----- | ----- | ----- | 
| `PrometheusTargetDown` | Detects failure of Prometheus's own scrape target | `2m` | Critical | 
| `PrometheusScrapeFailures` | Detects scrape sample-limit exceedance | `2m` | Warning | 

**`PrometheusTargetDown` expression:**

```
up{job="prometheus"} == 0

```

**`PrometheusScrapeFailures` expression:**

```
increase(
  prometheus_target_scrapes_exceeded_sample_limit_total[5m]
) > 0

```

The second rule detects a specific scrape failure condition: exceeding the configured sample limit. It is not a general detector for every possible scrape error.

> **Important Limitation:** Prometheus cannot evaluate its own alert rules or send notifications when its entire process is stopped. The self-monitoring rule only detects a failure of its own scrape target while Prometheus remains operational.

## 8. Alertmanager and Email Notifications

### 8.1 Purpose

Alertmanager receives alerts from Prometheus and manages their notification lifecycle, including:

* Alert grouping

* Notification routing

* Repeat notifications

* Resolved notifications

* Email delivery

### 8.2 SMTP Configuration

Alertmanager was configured to use Gmail SMTP:

```
global:
  smtp_smarthost: "smtp.gmail.com:587"
  smtp_from: "YOUR_EMAIL_ADDRESS"
  smtp_auth_username: "YOUR_EMAIL_ADDRESS"
  smtp_auth_password_file: "/etc/alertmanager/secrets/smtp_password"
  smtp_require_tls: true

```

The SMTP password is stored in a separate mounted secret file rather than directly in the public configuration.

### 8.3 Email Receiver

```
receivers:
  - name: "email-alerts"
    email_configs:
      - to: "YOUR_NOTIFICATION_EMAIL"
        send_resolved: true

```

The `send_resolved: true` setting enables notification when an alert returns to its resolved state.

### 8.4 Notification Grouping

```
group_by:
  - alertname
  - instance
  - severity

group_wait: 30s
group_interval: 5m
repeat_interval: 4h

```

These settings control how alerts are grouped and when notifications are sent.

### 8.5 Severity-Based Routing

Two routing policies were implemented, both using the `email-alerts` receiver (as does the default route):

| Severity | Initial Group Wait | Repeat Interval | 
| ----- | ----- | ----- | 
| **Critical** | `10s` | `1h` | 
| **Warning** | `30s` | `4h` | 

### 8.6 Validate Alertmanager Configuration

Validate configuration syntax:

```
docker run --rm \
  --entrypoint amtool \
  -v "$PWD/alertmanager:/etc/alertmanager:ro" \
  prom/alertmanager:latest \
  check-config /etc/alertmanager/alertmanager.yml

```

Test critical routing:

```
docker exec enterprise-alertmanager \
  amtool config routes test \
  --config.file=/etc/alertmanager/alertmanager.yml \
  severity=critical

```

Test warning routing:

```
docker exec enterprise-alertmanager \
  amtool config routes test \
  --config.file=/etc/alertmanager/alertmanager.yml \
  severity=warning

```

Both commands should resolve to:

```
email-alerts

```

## 9. Docker Compose Deployment

The monitoring services (**Prometheus**, **Alertmanager**, and **Grafana**) are managed through Docker Compose.

* Persistent Docker volumes are used for monitoring data.

* Configuration files are mounted into the appropriate containers.

* Service names provide internal Docker DNS resolution.

### Useful Commands

Start services:

```
docker compose up -d

```

Stop services:

```
docker compose down

```

Restart services:

```
docker compose restart

```

Inspect service status:

```
docker compose ps

```

View all logs:

```
docker compose logs -f

```

Inspect an individual service:

```
docker logs enterprise-prometheus
docker logs enterprise-alertmanager
docker logs enterprise-grafana

```

## 10. Docker Container Health Checks

Health checks were added to all three monitoring containers:

| Service | Health Endpoint | 
| ----- | ----- | 
| **Prometheus** | `/-/healthy` | 
| **Alertmanager** | `/-/healthy` | 
| **Grafana** | `/api/health` | 

### Health-Check Policy

* **Interval:** `30s`

* **Timeout:** `10s`

* **Retries:** `3`

* **Startup grace period:** `30s` for Prometheus and Alertmanager; `60s` for Grafana

* **Probe tools:** `wget` for Prometheus and Alertmanager; `curl` for Grafana

Verify container health:

```
docker compose ps

```

Expected status:

```
enterprise-prometheus     Up (healthy)
enterprise-alertmanager   Up (healthy)
enterprise-grafana        Up (healthy)

```

A running container is not automatically a healthy application. Health checks provide an additional indication that the application endpoint is responding.

## 11. Alert Testing and Validation

Monitoring alerts were tested using controlled simulations rather than relying solely on configuration validation.

### 11.1 CPU Alert Test

1. Temporarily reduced the CPU alert threshold from `85%` to `1%`.

2. Generated CPU load using `stress-ng`.

3. Observed the alert transition through `Inactive -> Pending -> Firing`.

4. Confirmed receipt of the firing email notification.

5. Restored the production threshold to `85%` after testing.

### 11.2 Node Exporter Failure Test

1. Temporarily stopped Node Exporter:

   ```
   sudo systemctl stop node_exporter
   
   ```

2. Confirmed Prometheus detected the failed scrape, `NodeExporterDown` fired, and Alertmanager delivered a critical email notification.

3. Restored the service:

   ```
   sudo systemctl start node_exporter
   
   ```

4. Confirmed the target returned to `UP` and the resolved email was received.

### 11.3 Missing-Target Test

1. Temporarily removed the managed-server scrape job from `prometheus.yml`.

2. Confirmed Prometheus no longer exposed the target's `up` series, `PrometheusTargetMissing` fired, and an email notification was received.

3. Restored the original configuration from backup and reloaded Prometheus.

### 11.4 Prometheus Self-Monitoring Test

1. Temporarily changed the Prometheus self-scrape target from port `9090` to port `9091`.

2. Confirmed the Prometheus process continued running while its own scrape target became unavailable, triggering `PrometheusTargetDown`.

3. Restored the original port, confirmed the target returned to `UP`, and verified receipt of the resolved notification.

### 11.5 Notification Lifecycle Verification

Both firing and resolved email notifications were successfully verified across the full pipeline:

```
Metric condition
      |
      v
Prometheus alert evaluation
      |
      v
Firing alert
      |
      v
Alertmanager
      |
      v
Gmail notification
      |
      v
Condition clears
      |
      v
Resolved notification

```

## 12. Security Considerations

### 12.1 Network Security

* Prometheus, Grafana, and Alertmanager host ports are bound to `localhost`.

* EC2 port `9100` is restricted to the trusted monitoring workstation's public IP (`/32`).

* Node Exporter is not exposed to unrestricted internet access.

* Only required monitoring communication paths are allowed.

### 12.2 Linux Service Security

* Node Exporter runs under a dedicated non-login account (`node_exporter`).

* The service uses `systemd` security restrictions.

* The exporter does not require `root` privileges for its standard metrics collection.

### 12.3 Secret Management

Sensitive information is kept outside version control. Files excluded via `.gitignore` include:

```
.env
.env.*
!.env.example

monitoring/grafana/.env
monitoring/alertmanager/secrets/
monitoring/prometheus/prometheus.yml.backup

```

The Alertmanager SMTP password file is mounted read-only into its container and protected with restrictive file permissions.

**Pre-commit verification commands:**

```
# Check working tree status
git status --short

# Verify sensitive files are ignored
git check-ignore -v monitoring/grafana/.env
git check-ignore -v monitoring/alertmanager/secrets/smtp_password

# Ensure sensitive files were never previously tracked
git ls-files monitoring/grafana/.env
git ls-files monitoring/alertmanager/secrets/smtp_password

```

> **Note:** `.gitignore` does not remove secrets from existing Git history. Previously committed credentials must be rotated and any necessary history cleanup handled separately.

## 13. Troubleshooting Reference

| Problem | Initial Checks | 
| ----- | ----- | 
| **Node Exporter target DOWN** | Run `systemctl status node_exporter`; check port `9100` and EC2 security group | 
| **Prometheus target missing** | Inspect `prometheus.yml` and reload Prometheus | 
| **Prometheus configuration error** | Run `promtool check config` | 
| **Alert rule not loading** | Run `promtool check rules` and inspect Prometheus alerts | 
| **Alertmanager restarting** | Inspect `docker logs enterprise-alertmanager` | 
| **Alertmanager configuration error** | Run `amtool check-config` | 
| **No email notification** | Check Alertmanager logs, SMTP configuration, and secret-file permissions | 
| **Grafana cannot query Prometheus** | Verify Grafana data source uses `http://prometheus:9090` | 
| **Grafana unavailable** | Inspect container logs and `/api/health` | 
| **Container unhealthy** | Inspect `docker inspect` health status and container logs | 

## 14. Operational Verification Checklist

Run through these checks after initial deployment, configuration changes, or workstation reboots to confirm end-to-end observability:

### Managed EC2 Host (Node Exporter)

* \[ \] `sudo systemctl is-active node_exporter` returns `active`.

* \[ \] `sudo ss -tulnp | grep 9100` shows `node_exporter` listening on TCP port `9100`.

* \[ \] EC2 Security Group allows inbound TCP `9100` strictly from the monitoring workstation's `/32` public IP.

### Local Monitoring Stack (Docker Compose)

* \[ \] `docker compose ps` shows `enterprise-prometheus`, `enterprise-alertmanager`, and `enterprise-grafana` all in `Up (healthy)` state.

* \[ \] Host ports `9090`, `9093`, and `3000` are bound to `127.0.0.1` (`localhost`) only.

### Metrics Scraping (Prometheus)

* \[ \] `promtool check config` and `promtool check rules` pass with zero errors.

* \[ \] `http://localhost:9090/targets` shows both `prometheus` and `enterprise-linux-server` in the `UP` state with recent scrape timestamps.

### Visualization (Grafana)

* \[ \] Grafana data source (`http://prometheus:9090`) passes the **Save & test** health check.

* \[ \] The **Enterprise Linux Server Monitoring** dashboard populates live data across all six panels without `No data` or `N/A` errors.

### Alerting & Notifications (Alertmanager)

* \[ \] `amtool check-config` succeeds and `amtool config routes test` routes both `severity=critical` and `severity=warning` to `email-alerts`.

* \[ \] Both firing and resolved test emails arrive in the target Gmail inbox.

### Security & Repository Hygiene

* \[ \] `git status --short` and `git check-ignore -v` confirm `.env` files, `smtp_password`, and `.backup` files are untracked and ignored before pushing commits.