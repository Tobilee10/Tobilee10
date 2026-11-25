# Prometheus Configuration and Operations Guide

## 1. Introduction

**Prometheus** is an open-source monitoring and alerting system designed to collect, store, query, and evaluate time-series metrics.

In the `enterprise-linux-server-deployment` project, Prometheus runs as a Docker container on the local Linux monitoring workstation and performs four core responsibilities:

* Scraping infrastructure metrics from **Node Exporter** on the managed AWS EC2 server.

* Storing collected metrics as time-series data.

* Evaluating alert rules at configured intervals.

* Forwarding firing and resolved alerts to **Alertmanager**.

## 2. Prometheus Architecture

The end-to-end monitoring and alerting flow is:

```text
AWS EC2 Ubuntu Server
        |
        v
Node Exporter (:9100)
        |
        | HTTP metrics endpoint (/metrics)
        v
Prometheus (:9090)
        |
        +------------------+
        |                  |
        v                  v
  Time-series DB      Alert Evaluation
                           |
                           v
                     Alertmanager (:9093)
                           |
                           v
                    Email Alerts (SMTP)

Grafana (:3000) ---> Prometheus HTTP API (http://prometheus:9090)
```

### Component Responsibilities

| Component | Responsibility |
| :--- | :--- |
| **Node Exporter** | Exposes Linux host metrics over HTTP on port `9100` |
| **Prometheus** | Scrapes targets, stores time-series data, evaluates rules, and dispatches alerts |
| **PromQL** | Queries, filters, and aggregates collected time-series metrics |
| **Alert rules** | Define PromQL conditions, durations, labels, and annotations for alerting |
| **Alertmanager** | Groups, routes, deduplicates, and delivers notifications |
| **Grafana** | Queries Prometheus and visualizes metrics in dashboards |

## 3. Prometheus Configuration Location

On the local monitoring workstation, configuration files are maintained under `monitoring/prometheus/` and mounted read-only into the container:

| Host Path | Container Mount Path | Purpose |
| :--- | :--- | :--- |
| `monitoring/prometheus/prometheus.yml` | `/etc/prometheus/prometheus.yml` | Main Prometheus configuration |
| `monitoring/prometheus/alerts/` | `/etc/prometheus/alerts/` | Alert rule YAML files |

## 4. Global Configuration

The `global` section sets default timing behavior across scrapes and rule evaluations:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
```

* **`scrape_interval` (`15s`):** Defines how frequently Prometheus attempts to pull metrics from configured targets.

* **`evaluation_interval` (`15s`):** Defines how frequently Prometheus evaluates alerting and recording rules.

`scrape_interval` and `evaluation_interval` operate independently.

## 5. Configuring Alertmanager Integration

Prometheus forwards alerts to Alertmanager over the shared Docker Compose network using internal service DNS:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "alertmanager:9093"
```

* **`alerting` / `alertmanagers`:** Enables alert dispatch and specifies notification destinations.

* **`static_configs` / `targets`:** Defines a static target using the Alertmanager container's Compose service name (`alertmanager`) and listening port (`9093`).

## 6. Loading Alert Rule Files

Prometheus discovers and loads alert rules using a wildcard path in `rule_files`:

```yaml
rule_files:
  - "/etc/prometheus/alerts/*.yml"
```

Separating rules into focused files makes maintenance easier:

| Rule File | Monitoring Responsibility |
| :--- | :--- |
| `availability-alerts.yml` | Node Exporter availability and missing targets |
| `cpu-alerts.yml` | CPU utilization |
| `disk-alerts.yml` | Filesystem / disk utilization |
| `memory-alerts.yml` | Memory utilization |
| `network-alerts.yml` | Incoming and outgoing network traffic |
| `prometheus-alerts.yml` | Prometheus self-monitoring |

## 7. Configuring Scrape Jobs

Scrape jobs define which endpoints Prometheus pulls metrics from. This deployment configures two jobs.

### 7.1 Prometheus Self-Monitoring

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets:
          - "localhost:9090"
```

Because Prometheus runs inside its own container network namespace, `localhost:9090` targets Prometheus's own HTTP metrics endpoint inside the `enterprise-prometheus` container.

### 7.2 Enterprise Linux Server Monitoring

```yaml
  - job_name: "enterprise-linux-server"
    static_configs:
      - targets:
          - "YOUR_EC2_PUBLIC_IP:9100"
```

Replace `YOUR_EC2_PUBLIC_IP` with your managed EC2 instance's current public IP address. Ensure the EC2 Security Group allows inbound TCP port `9100` strictly from the monitoring workstation's `/32` public IP, and never expose port `9100` to `0.0.0.0/0`.

## 8. Understanding the Complete Configuration

Combining the sections above gives the full `monitoring/prometheus/prometheus.yml` structure:

```yaml
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

This configuration establishes metric scrape cadence, rule evaluation cadence, Alertmanager routing target, alert rule discovery, self-monitoring, and managed EC2 host monitoring.

## 9. Understanding Prometheus Targets

Inspect live scrape targets at `http://localhost:9090/targets`, which shows job names, endpoints, scrape health, timestamps, durations, and last scrape errors.

| Target State | Meaning |
| :--- | :--- |
| `UP` | Prometheus successfully scraped the target (`up` series returns `1`) |
| `DOWN` | The scrape attempt failed (`up` series returns `0` while configured) |
| `UNKNOWN` | Target health has not yet been established |

If a target job or endpoint is removed completely from configuration, its `up` time series will no longer be present.

## 10. Understanding Prometheus Metrics

Each time series in Prometheus is uniquely identified by a **metric name** and a set of **key-value labels**, associated with timestamped **sample values**.

Common Node Exporter metrics used in this deployment include:

| Metric Name | Purpose |
| :--- | :--- |
| `node_cpu_seconds_total` | Accumulated CPU time by CPU core and mode (e.g., `idle`) |
| `node_memory_MemTotal_bytes` | Total physical memory in bytes |
| `node_memory_MemAvailable_bytes` | Estimated memory available for new processes without swapping |
| `node_filesystem_size_bytes` | Total filesystem capacity in bytes |
| `node_filesystem_avail_bytes` | Available filesystem space in bytes |
| `node_network_receive_bytes_total` | Cumulative bytes received by network interface |
| `node_network_transmit_bytes_total` | Cumulative bytes transmitted by network interface |
| `node_boot_time_seconds` | Host boot timestamp in Unix epoch seconds |
| `node_time_seconds` | Current host time in Unix epoch seconds |

Always verify metric names and label sets against live `/metrics` output before writing new queries.

## 11. PromQL Queries Used in the Project

**PromQL** (Prometheus Query Language) selects, filters, aggregates, and computes expressions over time-series data.

### 11.1 CPU Utilization

```promql
100 * (
  1 - avg by(instance) (
    rate(node_cpu_seconds_total{mode="idle"}[5m])
  )
)
```

Computes the per-rate of `idle` CPU time over a `5m` window, averages across cores per `instance`, and subtracts from `100` to get utilization percentage.

### 11.2 Memory Utilization

```promql
100 * (
  1 - (
    node_memory_MemAvailable_bytes /
    node_memory_MemTotal_bytes
  )
)
```

Uses `MemAvailable` rather than raw `MemFree` so page cache and reclaimable buffers are accounted for realistically.

### 11.3 Disk Utilization

```promql
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

Calculates root (`/`) filesystem utilization percentage while excluding pseudo/container filesystems (`tmpfs`, `overlay`, `squashfs`).

### 11.4 Available Disk Space

```promql
node_filesystem_avail_bytes{
  mountpoint="/",
  fstype!~"tmpfs|overlay|squashfs"
}
```

Returns available root filesystem bytes (set the Grafana panel unit to `GiB` for readable display).

### 11.5 Network Receive Rate

```promql
rate(node_network_receive_bytes_total{device!="lo"}[5m])
```

Calculates incoming network traffic in bytes per second over `5m`, excluding the loopback interface (`lo`).

### 11.6 Network Transmit Rate

```promql
rate(node_network_transmit_bytes_total{device!="lo"}[5m])
```

Calculates outgoing network traffic in bytes per second over `5m`, excluding the loopback interface (`lo`).

### 11.7 Server Uptime

```promql
node_time_seconds - node_boot_time_seconds
```

Calculates elapsed uptime in seconds since the host booted.

## 12. Configuring Alert Rules

Alert rules are grouped under `groups` in YAML files:

```yaml
groups:
  - name: example-alerts
    rules:
      - alert: ExampleAlert
        expr: up == 0
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: Example monitoring alert
          description: A monitoring target is unavailable.
```

| Field | Purpose |
| :--- | :--- |
| `groups` | Top-level list of rule groups |
| `name` | Unique name for the rule group |
| `alert` | Name of the alert emitted when firing |
| `expr` | PromQL boolean expression evaluated each `evaluation_interval` |
| `for` | Duration `expr` must remain true before transitioning from `Pending` to `Firing` |
| `labels` | Key-value labels attached to the alert (used for Alertmanager routing and grouping) |
| `annotations` | Descriptive metadata (such as `summary` and `description`) |

## 13. Alert Rules Implemented

The deployment defines nine alert rules across six YAML files (aligned with the monitoring baseline):

| Alert | Condition | Duration | Severity |
| :--- | :--- | :--- | :--- |
| `HighCPUUtilization` | CPU utilization `> 85%` | `5m` | `warning` |
| `HighMemoryUtilization` | Memory utilization `> 85%` | `5m` | `warning` |
| `HighDiskUtilization` | Root disk utilization `> 80%` | `5m` | `warning` |
| `HighNetworkReceive` | Incoming traffic `> 10 MiB/s` | `5m` | `warning` |
| `HighNetworkTransmit` | Outgoing traffic `> 10 MiB/s` | `5m` | `warning` |
| `NodeExporterDown` | Managed target is unreachable (`up == 0`) | `2m` | `critical` |
| `PrometheusTargetMissing` | Managed target series is absent (`absent(up...)`) | `2m` | `critical` |
| `PrometheusTargetDown` | Prometheus self-target is unreachable (`up{job="prometheus"} == 0`) | `2m` | `critical` |
| `PrometheusScrapeFailures` | Sample-limit exceedance counter increases (`increase(...[5m]) > 0`) | `2m` | `warning` |

*(Note: Thresholds represent baseline monitoring policies and should be reviewed against real workload behavior.)*

## 14. Understanding Alert States

Alerts move through lifecycle states as expressions evaluate:

```text
Inactive
   |
   | expr becomes true
   v
Pending  (for < "for" duration)
   |
   | expr stays true for "for" duration
   v
Firing   ---> Sent to Alertmanager (and resolved notification sent when expr clears)
   |
   | expr becomes false
   v
Inactive
```

* **`Inactive`:** Condition is not currently true.

* **`Pending`:** Condition is true, but the `for` duration has not yet elapsed.

* **`Firing`:** Condition remained true for the full `for` duration; Prometheus forwards the alert to Alertmanager, and sends a resolved notification once the condition clears.

## 15. Validating Prometheus Configuration

Use `promtool` inside the container to check syntax and rule structure before reloading:

```bash
docker exec enterprise-prometheus \
  promtool check config /etc/prometheus/prometheus.yml

for file in monitoring/prometheus/alerts/*.yml; do
    echo "Checking: $file"
    docker exec enterprise-prometheus \
      promtool check rules \
      "/etc/prometheus/alerts/$(basename "$file")" \
      || break
done
```

`promtool` validates syntax and schema structure, but does not verify live metric availability or query logic—always test PromQL expressions against live data as well.

## 16. Reloading Prometheus Configuration

After validation succeeds, trigger a configuration reload via Prometheus's HTTP lifecycle endpoint (requires `--web.enable-lifecycle` on the Prometheus container):

```bash
docker exec enterprise-prometheus \
  wget -qO- --post-data='' http://localhost:9090/-/reload
```

Then verify loaded targets at `http://localhost:9090/targets` and rule states at `http://localhost:9090/alerts`. If the reload fails, inspect `docker logs enterprise-prometheus` and re-check the configuration.

## 17. Prometheus Operational Commands

```bash
# Container status and logs
docker ps
docker logs enterprise-prometheus
docker logs -f enterprise-prometheus

# Configuration validation and reload
docker exec enterprise-prometheus \
  promtool check config /etc/prometheus/prometheus.yml

docker exec enterprise-prometheus \
  wget -qO- --post-data='' http://localhost:9090/-/reload

# Local health endpoint check
curl http://localhost:9090/-/healthy
```

Browser endpoints (bound to `127.0.0.1` on the workstation):

* **Expression browser & alerts:** `http://localhost:9090` / `http://localhost:9090/alerts`

* **Scrape targets:** `http://localhost:9090/targets`

## 18. Troubleshooting Reference

| Symptom | Likely Cause | First Diagnostic Action |
| :--- | :--- | :--- |
| Target `DOWN` | Network path, firewall, or exporter issue | Test `/metrics` endpoint and inspect `/targets` error |
| No metrics returned | Scrape job misconfiguration or missing exporter series | Query `up` and verify `prometheus.yml` targets |
| Alert stays `Pending` | `for` duration not yet elapsed or metric fluctuates | Inspect rule state at `/alerts` and check `for` value |
| Alert does not fire | Expression, threshold, or label mismatch | Run the PromQL query directly in `/graph` |
| Reload fails | Invalid YAML/rule syntax or lifecycle flag disabled | Run `promtool check config` and inspect container logs |
| Alert not delivered | Alertmanager connectivity or routing issue | Inspect Prometheus and Alertmanager container logs |

## 19. Operational Recommendations

* Pin explicit container image tags rather than relying on `:latest` for reproducible upgrades.

* Maintain regular backups of `prometheus.yml`, alert rules, and persistent volume data, and monitor TSDB disk growth.

* Keep web interfaces bound to `127.0.0.1` and use SSH tunneling or a VPN for remote access.

* Periodically review alert thresholds and test end-to-end notification delivery.

* Keep configuration files in Git, and ensure secrets and `.env` files remain excluded and never committed.

* Note that while Prometheus can alert on a scrape failure of its own target while running, an external monitor is needed if the Prometheus process or workstation itself goes offline.

## 20. Conclusion

Prometheus serves as the core metrics collection, querying, and alert-evaluation engine in this deployment. Together with **Node Exporter**, **Alertmanager**, and **Grafana**, it provides a repeatable, observable monitoring foundation for the managed EC2 Linux server.