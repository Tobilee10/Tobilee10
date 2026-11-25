# Grafana Dashboard and Visualization Guide

## 1. Introduction

**Grafana** is an open-source observability and visualization platform used to display time-series metrics collected by monitoring systems.

In the `enterprise-linux-server-deployment` project, Grafana provides a centralized dashboard for monitoring the performance and availability of an Ubuntu Linux server hosted on AWS EC2 by querying **Prometheus** as its datasource:

* **CPU utilization**

* **Memory utilization**

* **Disk utilization**

* **Available disk space**

* **Network traffic** (incoming and outgoing)

* **Server uptime**

## 2. Grafana Architecture

Grafana runs as a Docker container on the local Linux monitoring workstation and retrieves metrics from Prometheus over the Prometheus HTTP API rather than scraping **Node Exporter** directly:

```text
AWS EC2 Ubuntu Server
        |
        v
Node Exporter (:9100)
        |
        v
Prometheus (:9090)
        |
        | Prometheus HTTP API (http://prometheus:9090)
        v
Grafana (:3000)
        |
        v
Enterprise Linux Server Monitoring Dashboard
```

### Component Responsibilities

| Component | Responsibility |
| :--- | :--- |
| **Node Exporter** | Exposes Linux host metrics over HTTP on port `9100` |
| **Prometheus** | Scrapes targets, stores time-series data, and evaluates rules |
| **PromQL** | Queries, filters, and aggregates collected metrics |
| **Grafana** | Queries Prometheus and visualizes metrics in dashboards |

## 3. Grafana Deployment

Grafana is deployed via Docker Compose as container `enterprise-grafana` and bound strictly to the local loopback interface (`127.0.0.1:3000`):

```yaml
ports:
  - "127.0.0.1:3000:3000"
```

Binding to `127.0.0.1` prevents direct exposure on external network interfaces. For remote access, use an SSH tunnel or VPN.

### Operational Checks

```bash
# Check container status
docker ps

# Inspect Grafana container logs
docker logs enterprise-grafana

# Verify Grafana health endpoint
curl http://localhost:3000/api/health
```

## 4. Grafana Environment Configuration

Grafana administrator settings are supplied through `monitoring/grafana/.env` (excluded from Git via `.gitignore`):

```text
GF_SECURITY_ADMIN_USER
GF_SECURITY_ADMIN_PASSWORD
```

Supply credentials securely through the environment file and never publish actual passwords in documentation or version control.

## 5. Configuring Prometheus as a Datasource

### Configuration Procedure

1. Open `http://localhost:3000` and sign in with your configured administrator credentials.

2. Navigate to **Connections → Data sources → Add data source → Prometheus**.

3. Set the connection URL to:

   ```text
   http://prometheus:9090
   ```

4. Click **Save & test** to verify connectivity.

### Why Use `http://prometheus:9090`?

Grafana and Prometheus share the same Docker Compose network, where internal DNS resolves service names such as `prometheus:9090`. Using `localhost:9090` inside the Grafana container would point to the Grafana container itself rather than Prometheus.

## 6. Creating the Monitoring Dashboard

Create a dashboard named **`Enterprise Linux Server Monitoring`** with an appropriate refresh interval and time range for your workload.

### Recommended Dashboard Layout

| Panel | Visualization | Unit |
| :--- | :--- | :--- |
| **CPU Utilization** | Time series | Percent (`0–100`) |
| **Memory Utilization** | Time series | Percent (`0–100`) |
| **Disk Utilization** | Time series | Percent (`0–100`) |
| **Disk Available** | Time series or Stat | Bytes (IEC) → Gibibytes (`GiB`) |
| **Network Traffic** | Time series | Data rate → Bytes/sec (IEC) |
| **Server Uptime** | Stat or Time series | Time → Duration |

## 7. CPU Utilization Panel

**Purpose:** Displays the percentage of CPU capacity currently utilized on the managed Linux server.

```promql
100 * (
  1 - avg by(instance) (
    rate(node_cpu_seconds_total{mode="idle"}[5m])
  )
)
```

* **`rate(node_cpu_seconds_total{mode="idle"}[5m])`** computes the per-second rate of idle CPU time over a `5m` window.

* **`avg by(instance)`** averages the idle rate across CPU cores for each `instance`.

* **`1 - ...`** converts the idle fraction into busy CPU utilization, and multiplying by `100` expresses it as a percentage.

**Visualization settings:** Time series | Unit: Percent (`0–100`) | Legend: `{{instance}}` (or `CPU Utilization`). Sustained high CPU utilization warrants checking host process activity alongside workload baseline.

## 8. Memory Utilization Panel

**Purpose:** Displays the percentage of system memory not currently available to new workloads without swapping.

```promql
100 * (
  1 - (
    node_memory_MemAvailable_bytes /
    node_memory_MemTotal_bytes
  )
)
```

Using `node_memory_MemAvailable_bytes` rather than `node_memory_MemFree_bytes` provides a more accurate view on Linux because the kernel uses otherwise free memory for page cache and reclaimable buffers.

**Visualization settings:** Time series | Unit: Percent (`0–100`) | Legend: `{{instance}}` (or `Memory Utilization`).

## 9. Disk Utilization Panel

**Purpose:** Displays the percentage of root (`/`) filesystem capacity currently unavailable.

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

Excludes temporary and container/overlay filesystems (`tmpfs`, `overlay`, `squashfs`) and focuses on `/` so storage pressure is caught early.

**Visualization settings:** Time series | Unit: Percent (`0–100`) | Legend: `{{instance}}` (or `Disk Utilization`).

## 10. Available Disk Space Panel

**Purpose:** Shows actual remaining free space on the root (`/`) filesystem alongside percentage utilization.

```promql
node_filesystem_avail_bytes{
  mountpoint="/",
  fstype!~"tmpfs|overlay|squashfs"
}
```

**Visualization settings:** Time series or Stat | Unit: Data → Bytes (IEC) → Gibibytes (`GiB`) | Legend: `{{instance}}` (or `Available Disk Space`).

## 11. Network Traffic Panel

**Purpose:** Displays incoming (receive) and outgoing (transmit) traffic rates on non-loopback network interfaces.

```promql
# Incoming network traffic (bytes/sec)
rate(node_network_receive_bytes_total{device!="lo"}[5m])

# Outgoing network traffic (bytes/sec)
rate(node_network_transmit_bytes_total{device!="lo"}[5m])
```

`rate(...[5m])` converts cumulative byte counters into per-second rates while `device!="lo"` excludes loopback traffic.

| Metric | Meaning | Legend Pattern |
| :--- | :--- | :--- |
| **Receive** | Data entering the network interface | `Receive - {{device}}` (e.g., `Receive - eth0`) |
| **Transmit** | Data leaving the network interface | `Transmit - {{device}}` (e.g., `Transmit - eth0`) |

**Visualization settings:** Time series | Unit: Data rate → Bytes/sec (IEC). Use the actual `device` label returned by Prometheus rather than hardcoding an interface name.

## 12. Server Uptime Panel

**Purpose:** Displays how long the managed server has been running since its last boot.

```promql
node_time_seconds - node_boot_time_seconds
```

Subtracts the boot timestamp (`node_boot_time_seconds`) from the current timestamp (`node_time_seconds`) in Unix seconds. A sudden drop indicates a host reboot.

**Visualization settings:** Stat or Time series | Unit: Time → Duration | Display name: `Server Uptime`.

## 13. Understanding Grafana Units and Legends

Prometheus stores raw numeric samples (for example, `1073741824` bytes equals `1 GiB`). Configuring proper units and legends makes panels unambiguous:

| Metric | Recommended Unit |
| :--- | :--- |
| **CPU utilization** | Percent (`0–100`) |
| **Memory utilization** | Percent (`0–100`) |
| **Disk utilization** | Percent (`0–100`) |
| **Available disk space** | Gibibytes (`GiB`) |
| **Network traffic** | Bytes/sec (IEC) |
| **Server uptime** | Duration |

Clear legends (such as `Receive - eth0` and `Transmit - eth0` when `eth0` is the active interface) help operators distinguish series quickly.

## 14. Dashboard Validation

First confirm that the Prometheus target is `UP` at `http://localhost:9090/targets`, then verify each panel query and setting:

```promql
# CPU
100 * (1 - avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])))

# Memory
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Disk available
node_filesystem_avail_bytes{mountpoint="/",fstype!~"tmpfs|overlay|squashfs"}

# Network receive
rate(node_network_receive_bytes_total{device!="lo"}[5m])

# Uptime
node_time_seconds - node_boot_time_seconds
```

For every panel, verify that:

1. The query returns live data within the selected dashboard time range.

2. The visualization type and unit match the metric.

3. Legend labels are clear and accurate.

## 15. Grafana Troubleshooting

| Issue | Diagnostic & Resolution Steps |
| :--- | :--- |
| **Grafana inaccessible** | Run `docker ps`, check `docker logs enterprise-grafana`, test `curl http://localhost:3000/api/health`, and verify `127.0.0.1:3000:3000` port binding. |
| **Datasource connection fails** | Confirm URL is `http://prometheus:9090` and verify the Prometheus container is running and healthy. |
| **Dashboard shows `No data`** | Check target status in Prometheus, datasource connectivity, dashboard time range, and run the PromQL query directly in Prometheus (`http://localhost:9090`). |
| **Network panel shows no data** | Inspect `node_network_receive_bytes_total` to verify active interface names (`device`) and check `device!="lo"` filters. |
| **Disk panel shows unexpected values** | Inspect `node_filesystem_size_bytes` and `node_filesystem_avail_bytes` labels (`mountpoint` and `fstype`) before adjusting the query. |

## 16. Dashboard Persistence and Backup

Grafana persists state in the named Docker volume `grafana_data` across container recreations, but volumes do not replace backups:

* Export dashboard JSON definitions and store them in version control.

* Back up `grafana_data` and verify restoration periodically.

* Keep administrator credentials protected and out of source control.

## 17. Operational Recommendations

* Use clear dashboard and panel titles, appropriate units, and descriptive legends.

* Avoid overly expensive PromQL queries and choose sensible refresh intervals.

* Monitor both resource utilization and target availability, and review queries when exporter versions change.

* Maintain regular backups of dashboard definitions and configuration files.

## 18. Conclusion

Grafana completes the visual observability layer for the `enterprise-linux-server-deployment` stack—turning Prometheus metrics from **Node Exporter** into clear panels for CPU, memory, disk, network traffic, and uptime alongside **Alertmanager** notifications.