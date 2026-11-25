# Monitoring System Deployment Guide

## 1. Introduction

This document provides the installation, configuration, deployment, validation, and operational procedures for the monitoring and alerting solution implemented in the `enterprise-linux-server-deployment` project.

The solution monitors an Ubuntu Linux server hosted on AWS EC2 using **Prometheus**, **Node Exporter**, **Grafana**, **Alertmanager**, and **Docker Compose**. Node Exporter runs directly on the managed EC2 server as a `systemd` service, while Prometheus, Grafana, and Alertmanager run as Docker containers on a separate local Linux workstation.

The deployment provides:

* Infrastructure metrics collection (CPU, memory, disk, network, and server availability).

* Visualization through Grafana dashboards.

* Automated alert evaluation and email notifications.

* Container health checks and persistent monitoring data storage.

## 2. Architecture Overview

The implementation consists of two environments:

### 2.1 Managed Server — AWS EC2

The managed server is an Ubuntu Linux EC2 instance hosting:

* **Node Exporter `1.12.1`** running under a dedicated `node_exporter` Linux service account.

* A hardened `systemd` unit exposing host-level metrics on TCP port `9100`.

### 2.2 Monitoring Workstation — Local Linux

The local Linux workstation hosts the monitoring stack through Docker Compose:

| Component | Responsibility | Port | 
| :--- | :--- | ---: | 
| **Prometheus** | Metrics collection and alert evaluation | `9090` | 
| **Grafana** | Metrics visualization | `3000` | 
| **Alertmanager** | Alert grouping and notifications | `9093` | 
| **Node Exporter** | Host metrics exposure (on EC2) | `9100` | 

> **Operational Dependency:** Because the monitoring stack runs on a local workstation, the workstation must remain powered on and connected to the internet for continuous monitoring (see [Section 18](#18-known-limitations)).

### 2.3 Monitoring Data Flow

1. Node Exporter collects operating-system metrics from the EC2 server and exposes them via HTTP on port `9100`.

2. Prometheus scrapes the Node Exporter endpoint every `15s` and stores the time-series data.

3. Grafana queries Prometheus using PromQL to render dashboard panels.

4. Prometheus continuously evaluates alert rules and forwards firing and resolved alerts to Alertmanager.

5. Alertmanager groups and routes notifications through Gmail SMTP to the configured recipient.

## 3. Prerequisites

### Managed EC2 Server

* Ubuntu Linux installed with SSH access available.

* Sufficient disk space and memory.

* AWS security group access and outbound internet connectivity for package installation.

### Local Monitoring Workstation

* Linux operating system with Docker Engine and the Docker Compose plugin installed.

* Internet connectivity and outbound access to the managed EC2 server on TCP port `9100`.

### Accounts & Privileges

* AWS account access to configure Security Group rules.

* A Gmail account with a **Gmail App Password** generated for SMTP authentication.

* Administrative privileges (`sudo`) for configuring `systemd`, Docker, and AWS networking.

## 4. Installing Node Exporter on the EC2 Server

The project uses Node Exporter version `1.12.1` to collect hardware and operating-system metrics in Prometheus format.

### 4.1 Connect and Install Prerequisites

Connect to the EC2 server from your local workstation (replacing the key filename and public IP with your own):

```
ssh -i your-key.pem sysadmin@YOUR_EC2_PUBLIC_IP

```

Update the package index and install `wget` and `tar`:

```
sudo apt update && sudo apt install -y wget tar

```

### 4.2 Download, Extract, and Install the Binary

Download the official Linux AMD64 release, extract the archive, and install the binary into `/usr/local/bin`:

```
cd /tmp

VERSION="1.12.1"
ARCH="amd64"
FILE="node_exporter-${VERSION}.linux-${ARCH}.tar.gz"

wget "https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/${FILE}"
tar -xzf "$FILE"

sudo install -o root -g root -m 0755 \
  "node_exporter-${VERSION}.linux-${ARCH}/node_exporter" \
  /usr/local/bin/node_exporter

```

*(For production deployments, verify the archive SHA-256 checksum against the official release manifest before extracting.)*

Verify the installed version (`node_exporter, version 1.12.1`):

```
/usr/local/bin/node_exporter --version

```

### 4.3 Create a Dedicated Linux Service Account

Create an unprivileged system account with no home directory or interactive login shell so Node Exporter does not run as `root`:

```
sudo useradd \
  --system \
  --no-create-home \
  --shell /usr/sbin/nologin \
  node_exporter

id node_exporter

```

## 5. Configuring Node Exporter with systemd

Create the `systemd` unit file at `/etc/systemd/system/node_exporter.service`:

```
sudo nano /etc/systemd/system/node_exporter.service

```

Add the following configuration:

```
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

Restart=on-failure
RestartSec=5s

NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target

```

### 5.1 Service Configuration Reference

| Directive | Explanation | 
| :--- | :--- | 
| `User` / `Group` | Runs Node Exporter using the dedicated `node_exporter` account | 
| `Type=simple` | Runs the process in the foreground | 
| `ExecStart` | Defines the Node Exporter executable path | 
| `Restart` / `RestartSec` | Automatically restarts the service 5 seconds after an unexpected failure | 
| `NoNewPrivileges=true` | Prevents the process from acquiring additional privileges | 
| `ProtectSystem=full` | Mounts `/usr`, `/boot`, and `/etc` read-only for the service | 
| `ProtectHome=true` | Blocks access to `/home`, `/root`, and `/run/user` | 
| `PrivateTmp=true` | Provides an isolated temporary directory | 

### 5.2 Enable, Start, and Verify the Service

Reload `systemd`, enable automatic startup, and start Node Exporter:

```
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

```

Verify that the service is active, enabled at boot, listening on port `9100`, and serving metrics:

```
sudo systemctl status node_exporter --no-pager
sudo systemctl is-enabled node_exporter
sudo ss -tulnp | grep 9100
curl http://localhost:9100/metrics

```

Successful output from `/metrics` includes Prometheus-formatted series such as `node_cpu_seconds_total`, `node_memory_MemTotal_bytes`, `node_memory_MemAvailable_bytes`, `node_filesystem_size_bytes`, `node_network_receive_bytes_total`, `node_network_transmit_bytes_total`, and `node_boot_time_seconds`.

### 5.3 Operational Commands Reference

```
sudo systemctl status node_exporter     # Check service status
sudo systemctl start node_exporter      # Start service
sudo systemctl stop node_exporter       # Stop service
sudo systemctl restart node_exporter    # Restart service
sudo systemctl enable node_exporter     # Enable at boot
sudo journalctl -u node_exporter -f     # Stream live logs

```

## 6. Configuring AWS Network Access

### 6.1 Configure the EC2 Security Group

In the AWS Management Console, navigate to **EC2 → Instances → Select the managed instance → Security → Security groups** and add an inbound rule:

| Setting | Value | 
| :--- | :--- | 
| **Type** | Custom TCP | 
| **Protocol** | TCP | 
| **Port** | `9100` | 
| **Source** | `YOUR_WORKSTATION_PUBLIC_IP/32` | 

> **Security Note:** Restrict port `9100` strictly to your workstation's `/32` public IP. Never expose Node Exporter to `0.0.0.0/0`.

### 6.2 Test Remote Connectivity

From the local monitoring workstation, verify reachability:

```
curl http://YOUR_EC2_PUBLIC_IP:9100/metrics

```

If connectivity fails, check the EC2 Security Group inbound rules, VPC Network ACLs, route tables, `node_exporter` service status, and whether your workstation's public IP has changed.

## 7. Preparing the Monitoring Environment

On the local workstation, navigate to the project root:

```
cd ~/Desktop/tobilee10/Tobilee10/enterprise-linux-server-deployment

```

The `monitoring/` directory is structured as follows:

```
monitoring/
├── alertmanager/
│   ├── alertmanager.yml
│   └── secrets/
│       └── smtp_password
├── grafana/
│   └── .env
├── prometheus/
│   ├── prometheus.yml
│   └── alerts/
│       ├── availability-alerts.yml
│       ├── cpu-alerts.yml
│       ├── disk-alerts.yml
│       ├── memory-alerts.yml
│       ├── network-alerts.yml
│       └── prometheus-alerts.yml
└── docker-compose.yml

```

> **Credential Safety:** `monitoring/grafana/.env` and `monitoring/alertmanager/secrets/smtp_password` contain sensitive secrets and must never be committed to Git (see [Section 15](#15-security-and-git-hygiene)).

## 8. Configuring Prometheus

### 8.1 Prometheus Configuration File

Configure `monitoring/prometheus/prometheus.yml` (replacing `YOUR_EC2_PUBLIC_IP` with your instance's public IP):

```
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "alertmanager:9093"

rule_files:
  - "/etc/prometheus/alerts/*.yml"

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

### 8.2 Configuration Reference

| Key | Purpose | 
| :--- | :--- | 
| `scrape_interval` | Collects metrics from targets every `15s` | 
| `evaluation_interval` | Evaluates alert rules every `15s` | 
| `alertmanagers` | Routes alerts to Alertmanager via Docker DNS (`alertmanager:9093`) | 
| `rule_files` | Loads all YAML alert rule files from `/etc/prometheus/alerts/` | 
| `job_name: "prometheus"` | Scrapes Prometheus's own HTTP endpoint (`localhost:9090` inside the container) | 
| `job_name: "enterprise-linux-server"` | Scrapes Node Exporter on the managed EC2 instance | 

### 8.3 Validate Prometheus Configuration

Once the stack is running, validate the configuration syntax and loaded rule files:

```
docker exec enterprise-prometheus \
  promtool check config /etc/prometheus/prometheus.yml

```

Expected output reports `SUCCESS: /etc/prometheus/prometheus.yml is valid prometheus config file syntax` along with the six loaded rule files.

## 9. Configuring Prometheus Alert Rules

Alert rules are organized into six YAML files containing nine rules in total:

| File | Responsibility | 
| :--- | :--- | 
| `availability-alerts.yml` | Node Exporter availability and missing targets | 
| `cpu-alerts.yml` | CPU utilization | 
| `disk-alerts.yml` | Disk utilization | 
| `memory-alerts.yml` | Memory utilization | 
| `network-alerts.yml` | Incoming and outgoing network traffic | 
| `prometheus-alerts.yml` | Prometheus self-monitoring | 

### 9.1 Resource Utilization Alerts

| Alert | File | Threshold & Duration | Severity | PromQL Expression | 
| :--- | :--- | :--- | :--- | :--- | 
| `HighCPUUtilization` | `cpu-alerts.yml` | `> 85%` for `5m` | `warning` | `100 * (1 - avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) > 85` | 
| `HighMemoryUtilization` | `memory-alerts.yml` | `> 85%` for `5m` | `warning` | `100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) > 85` | 
| `HighDiskUtilization` | `disk-alerts.yml` | `> 80%` for `5m` | `warning` | `100 * (1 - node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs\|overlay\|squashfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs\|overlay\|squashfs"}) > 80` | 
| `HighNetworkReceive` | `network-alerts.yml` | `> 10 MiB/s` for `5m` | `warning` | `sum by(instance) (rate(node_network_receive_bytes_total{device!="lo"}[5m])) > 10485760` | 
| `HighNetworkTransmit` | `network-alerts.yml` | `> 10 MiB/s` for `5m` | `warning` | `sum by(instance) (rate(node_network_transmit_bytes_total{device!="lo"}[5m])) > 10485760` | 

*(Note: Network and resource thresholds are baseline starting policies and should be tuned to match actual production workload patterns.)*

### 9.2 Availability and Self-Monitoring Alerts

| Alert | File | Duration | Severity | PromQL Expression | Purpose | 
| :--- | :--- | :--- | :--- | :--- | :--- | 
| `NodeExporterDown` | `availability-alerts.yml` | `2m` | `critical` | `up{job="enterprise-linux-server"} == 0` | Detects a configured target that Prometheus cannot scrape | 
| `PrometheusTargetMissing` | `availability-alerts.yml` | `2m` | `critical` | `absent(up{job="enterprise-linux-server"})` | Detects when the managed server target disappears from scrape series | 
| `PrometheusTargetDown` | `prometheus-alerts.yml` | `2m` | `critical` | `up{job="prometheus"} == 0` | Detects when Prometheus cannot scrape its own endpoint while still running | 
| `PrometheusScrapeFailures` | `prometheus-alerts.yml` | `2m` | `warning` | `increase(prometheus_target_scrapes_exceeded_sample_limit_total[5m]) > 0` | Detects scrape sample-limit exceedance events | 

### 9.3 Validate All Alert Rules

Validate all six rule files inside the running Prometheus container:

```
for file in monitoring/prometheus/alerts/*.yml; do
    echo "Checking: $file"
    docker exec enterprise-prometheus \
      promtool check rules \
      "/etc/prometheus/alerts/$(basename "$file")" \
      || break
done

```

All six files should validate cleanly and report nine rules in total.

## 10. Deploying the Monitoring Stack with Docker Compose

### 10.1 Services and Health Endpoints

| Service | Container Name | Image | Host Binding | Health Endpoint | 
| :--- | :--- | :--- | :--- | :--- | 
| **Prometheus** | `enterprise-prometheus` | `prom/prometheus:latest` | `127.0.0.1:9090` | `http://localhost:9090/-/healthy` | 
| **Alertmanager** | `enterprise-alertmanager` | `prom/alertmanager:latest` | `127.0.0.1:9093` | `http://localhost:9093/-/healthy` | 
| **Grafana** | `enterprise-grafana` | `grafana/grafana:latest` | `127.0.0.1:3000` | `http://localhost:3000/api/health` | 

All three services use `restart: unless-stopped`, mount configuration and secret files read-only, and configure Docker health checks. In `grafana/.env`, set the administrator username using `GF_SECURITY_ADMIN_USER=admin`.

### 10.2 Persistent Docker Volumes

| Volume | Purpose | 
| :--- | :--- | 
| `prometheus_data` | Prometheus time-series database | 
| `alertmanager_data` | Alertmanager notification and silence state | 
| `grafana_data` | Grafana dashboards, data sources, and user settings | 

*(Persistent volumes preserve data across container recreations, but they do not replace independent off-host backups.)*

### 10.3 Validate, Start, and Inspect the Stack

Validate the Compose configuration syntax (`0` exit code indicates valid syntax):

```
docker compose -f monitoring/docker-compose.yml config -q && echo "Valid"

```

Start the monitoring services in detached mode and verify that all containers report `healthy`:

```
docker compose -f monitoring/docker-compose.yml up -d
docker compose -f monitoring/docker-compose.yml ps

```

Inspect container logs when needed:

```
docker logs enterprise-prometheus
docker logs enterprise-alertmanager
docker logs enterprise-grafana
docker logs -f enterprise-prometheus   # Follow live logs (Ctrl+C to exit)

```

## 11. Configuring Grafana

### 11.1 Access Grafana and Add Prometheus Data Source

1. Open `http://localhost:3000` and sign in with your configured administrator credentials.

2. Navigate to **Connections → Data sources → Add data source → Prometheus**.

3. Set the Prometheus server URL to `http://prometheus:9090` (using internal Docker DNS).

4. Click **Save & test** to verify connectivity.

### 11.2 Create the Monitoring Dashboard

Create a dashboard named **`Enterprise Linux Server Monitoring`** with six panels using the following PromQL queries:

| Panel | PromQL Query | Notes | 
| :--- | :--- | :--- | 
| **CPU Utilization** | `100 * (1 - avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])))` | Percentage of non-idle CPU time | 
| **Memory Utilization** | `100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)` | Uses `MemAvailable` rather than raw `MemFree` | 
| **Disk Utilization** | `100 * (1 - node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs\|overlay\|squashfs"} / node_filesystem_size_bytes{mountpoint="/",fstype!~"tmpfs\|overlay\|squashfs"})` | Root filesystem usage percentage | 
| **Disk Available** | `node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs\|overlay\|squashfs"}` | Set panel unit to **`GiB`** | 
| **Network Traffic** | In: `rate(node_network_receive_bytes_total{device!="lo"}[5m])`<br>Out: `rate(node_network_transmit_bytes_total{device!="lo"}[5m])` | Excludes loopback (`lo`) interface | 
| **Server Uptime** | `node_time_seconds - node_boot_time_seconds` | Elapsed uptime in seconds | 

## 12. Configuring Alertmanager and Email Notifications

### 12.1 Gmail SMTP and Secret Storage

Alertmanager delivers notifications via Gmail SMTP (`smtp.gmail.com:587`, TLS required) using a **Gmail App Password** rather than your primary account password.

Store the App Password in `monitoring/alertmanager/secrets/smtp_password`, which is mounted read-only into the container and referenced in `monitoring/alertmanager/alertmanager.yml`:

```
smtp_auth_password_file: /etc/alertmanager/secrets/smtp_password

```

### 12.2 Routing, Timing, and Recovery Notifications

`monitoring/alertmanager/alertmanager.yml` routes both `critical` and `warning` alerts to the `email-alerts` receiver with `send_resolved: true` enabled so recovery emails are sent when conditions clear.

| Severity | Group Wait | Group Interval | Repeat Interval | Receiver | 
| :--- | ---: | ---: | ---: | :--- | 
| **Critical** | `10s` | `5m` | `1h` | `email-alerts` | 
| **Warning** | `30s` | `5m` | `4h` | `email-alerts` | 

### 12.3 Validate Configuration and Routing

Validate `alertmanager.yml` and confirm that both severity levels resolve to `email-alerts`:

```
docker exec enterprise-alertmanager \
  amtool check-config /etc/alertmanager/alertmanager.yml

docker exec enterprise-alertmanager \
  amtool config routes test \
  --config.file=/etc/alertmanager/alertmanager.yml \
  severity=critical

docker exec enterprise-alertmanager \
  amtool config routes test \
  --config.file=/etc/alertmanager/alertmanager.yml \
  severity=warning

```

You can also inspect active alerts and routing state in the Alertmanager web UI at `http://localhost:9093`.

## 13. Monitoring Validation and Testing

### 13.1 Endpoint and UI Checks

* **Node Exporter (on EC2):** Confirm `sudo systemctl status node_exporter` is active and `curl http://localhost:9100/metrics` returns metrics.

* **Prometheus Targets (`http://localhost:9090/targets`):** Confirm both `prometheus` and `enterprise-linux-server` are `UP`.

* **Prometheus Alerts (`http://localhost:9090/alerts`):** Verify rules transition cleanly across `Inactive` → `Pending` → `Firing`.

* **Grafana (`http://localhost:3000`):** Confirm all six dashboard panels render live metrics.

* **Alertmanager (`http://localhost:9093`):** Confirm firing alerts arrive and trigger both firing and resolved emails.

### 13.2 Completed Simulation Tests

| Test Scenario | Expected Outcome | Status | 
| :--- | :--- | :--- | 
| CPU threshold lowered to `1%` + `stress-ng` load | `HighCPUUtilization` transitions to `Firing` and sends email | Verified | 
| `sudo systemctl stop node_exporter` | `NodeExporterDown` fires critical email | Verified | 
| `sudo systemctl start node_exporter` | `NodeExporterDown` resolves and sends recovery email | Verified | 
| Managed scrape job temporarily removed from `prometheus.yml` | `PrometheusTargetMissing` fires alert | Verified | 
| Managed scrape job restored and reloaded | `PrometheusTargetMissing` resolves | Verified | 
| Prometheus self-scrape port changed (`9090` → `9091`) | `PrometheusTargetDown` fires critical alert | Verified | 
| Prometheus self-scrape port restored to `9090` | `PrometheusTargetDown` resolves and sends recovery email | Verified | 

## 14. Configuration Reload and Service Management

### 14.1 Reload Prometheus Without Downtime

After validating changes to `prometheus.yml` or alert rules, trigger a hot reload via the enabled lifecycle API:

```
docker exec enterprise-prometheus \
  wget -qO- --post-data='' \
  http://localhost:9090/-/reload

```

### 14.2 Manage the Docker Compose Stack

```
docker compose -f monitoring/docker-compose.yml up -d      # Start services
docker compose -f monitoring/docker-compose.yml restart    # Restart services
docker compose -f monitoring/docker-compose.yml down       # Stop containers (preserves volumes)
docker compose -f monitoring/docker-compose.yml ps         # Check container health
docker volume ls                                           # List persistent volumes

```

> **Warning:** Avoid running `docker compose down -v` unless you intentionally want to destroy persistent metric, alert, and dashboard volumes.

## 15. Security and Git Hygiene

### 15.1 Infrastructure & Container Hardening

* **EC2 Host:** Node Exporter runs as an unprivileged `node_exporter` user under `systemd` hardening (`NoNewPrivileges`, `ProtectSystem=full`, `ProtectHome=true`, `PrivateTmp=true`), with inbound TCP `9100` restricted to the workstation's `/32` IP.

* **Monitoring Workstation:** Prometheus (`9090`), Grafana (`3000`), and Alertmanager (`9093`) bind strictly to `127.0.0.1`. For remote access, use an SSH tunnel or VPN.

* **Secrets:** SMTP passwords are stored in a read-only mounted secret file outside `alertmanager.yml`.

### 15.2 Git Ignore Verification

Ensure `.gitignore` excludes all local environment and secret files:

```
.env
.env.*
!.env.example

monitoring/grafana/.env
monitoring/alertmanager/secrets/
monitoring/prometheus/prometheus.yml.backup

```

Verify before committing that sensitive files are ignored and untracked:

```
git check-ignore -v monitoring/grafana/.env monitoring/alertmanager/secrets/smtp_password
git ls-files monitoring/grafana/.env monitoring/alertmanager/secrets/smtp_password

```

*(If credentials were ever committed previously, rotate them immediately and purge them from Git history before pushing.)*

## 16. Troubleshooting

| Symptom | Diagnostic Commands & Resolution | 
| :--- | :--- | 
| **Node Exporter not running** | Run `sudo systemctl status node_exporter` and `sudo journalctl -u node_exporter -n 50 --no-pager`; restart with `sudo systemctl restart node_exporter`. | 
| **Prometheus target `DOWN`** | Test `curl http://YOUR_EC2_PUBLIC_IP:9100/metrics` from the workstation; verify the EC2 Security Group `/32` IP rule and `node_exporter` status. | 
| **Prometheus container restarting** | Inspect `docker logs enterprise-prometheus` and validate syntax with `promtool check config /etc/prometheus/prometheus.yml`. | 
| **Alertmanager container restarting** | Inspect `docker logs enterprise-alertmanager` and validate syntax with `amtool check-config /etc/alertmanager/alertmanager.yml`. | 
| **Grafana cannot query Prometheus** | Confirm the Grafana data source URL is set to `http://prometheus:9090` and inspect `docker logs enterprise-grafana`. | 
| **Email notifications not arriving** | Check `docker logs enterprise-alertmanager`; verify `smtp.gmail.com:587`, Gmail App Password validity, secret file mount permissions, routing rules, and spam folder. | 

## 17. Operational Checklist

### Managed EC2 Server

* \[ \] Node Exporter `1.12.1` installed and verified.

* \[ \] Dedicated `node_exporter` system account created.

* \[ \] `systemd` service configured, enabled at boot, and active.

* \[ \] Metrics endpoint responding on port `9100`.

* \[ \] EC2 Security Group restricts inbound TCP `9100` to workstation `/32` IP.

### Monitoring Stack

* \[ \] Docker Engine and Docker Compose plugin installed.

* \[ \] `prometheus.yml` and all six alert rule files validated via `promtool`.

* \[ \] `enterprise-prometheus`, `enterprise-alertmanager`, and `enterprise-grafana` all report `Up (healthy)`.

* \[ \] Persistent volumes (`prometheus_data`, `alertmanager_data`, `grafana_data`) created.

### Grafana & Alerting

* \[ \] Prometheus data source (`http://prometheus:9090`) connected and tested.

* \[ \] **Enterprise Linux Server Monitoring** dashboard renders all six panels.

* \[ \] `alertmanager.yml` validated and `critical`/`warning` routes tested via `amtool`.

* \[ \] Firing and resolved Gmail notifications verified end-to-end.

### Security & Git Hygiene

* \[ \] Sensitive `.env` and `smtp_password` files ignored and untracked in Git.

* \[ \] Monitoring web UIs bound exclusively to `127.0.0.1`.

## 18. Known Limitations

This implementation is designed as a practical monitoring lab and portfolio project rather than a highly available production platform:

1. **Single workstation dependency:** Monitoring availability depends on the local workstation remaining powered on and connected to the internet.

2. **Local storage only:** Prometheus uses local Docker volume storage rather than a distributed long-term metrics backend.

3. **Single notification channel:** Alert delivery relies solely on Gmail SMTP email.

4. **No external dead-man's-switch:** While Prometheus can alert if its own scrape target fails *while the Prometheus process is running*, it cannot evaluate rules or send notifications if the Prometheus process or host workstation goes down entirely.

## 19. Future Improvements

* Deploy the monitoring stack on a dedicated, always-on server or managed platform.

* Add an independent external availability check (dead-man's-switch) to monitor the monitoring host itself.

* Implement automated off-host backups for Prometheus and Grafana volumes.

* Add TLS termination and centralized authentication (SSO/OIDC) for remote web access.

* Integrate remote write / long-term metrics storage (e.g., Thanos or VictoriaMetrics) and centralized log aggregation (e.g., Grafana Loki).

* Expand coverage to application-level metrics and additional alerting channels (Slack, PagerDuty).

* Provision the monitoring stack and AWS firewall rules using Infrastructure as Code (Terraform and Ansible).

## 20. Conclusion

This deployment guide demonstrates an end-to-end infrastructure monitoring and alerting implementation combining Linux `systemd` hardening, AWS EC2 Security Group isolation, Node Exporter metrics collection, Prometheus rule evaluation, Grafana visualization, Alertmanager email routing, and Docker Compose orchestration.