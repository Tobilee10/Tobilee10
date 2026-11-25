# Monitoring System Troubleshooting Guide

## 1. Introduction

This guide documents common issues encountered when deploying, operating, and maintaining the monitoring stack in the `enterprise-linux-server-deployment` project (**Node Exporter**, **Prometheus**, **Grafana**, **Alertmanager**, and **Docker Compose**). It provides systematic diagnostic steps, validation commands, and corrective actions.

## 2. Troubleshooting Methodology

Follow this sequence when investigating a monitoring issue:

1. Identify the affected component.
2. Check the component's service or container status.
3. Inspect its logs.
4. Verify configuration files.
5. Test network connectivity.
6. Validate the relevant endpoint.
7. Apply the correction.
8. Restart or reload the affected component.
9. Confirm that the problem is resolved.

> **Best Practice:** Change one configuration at a time so the root cause remains clearly identifiable.

## 3. Node Exporter Troubleshooting

### Problem: Node Exporter is not running

Inspect service status, recent logs, the installed binary, and port `9100` on the EC2 server:

```bash
sudo systemctl status node_exporter --no-pager
sudo journalctl -u node_exporter -n 50 --no-pager
ls -l /usr/local/bin/node_exporter
sudo ss -tulnp | grep 9100
```

**Corrective action & verification:**

```bash
sudo systemctl restart node_exporter
sudo systemctl enable node_exporter
sudo systemctl is-active node_exporter
```

### Problem: Node Exporter metrics endpoint is inaccessible

1. **Test locally on the EC2 server:**

   ```bash
   curl http://localhost:9100/metrics
   ```

   If this fails, investigate the `node_exporter` `systemd` service and port `9100` binding above.

2. **Test remotely from the monitoring workstation:**

   ```bash
   curl http://YOUR_EC2_PUBLIC_IP:9100/metrics
   ```

   If local access succeeds but remote access fails, check:
   * EC2 Security Group inbound rules (ensure TCP port `9100` allows traffic strictly from your workstation's `/32` public IP).
   * VPC Network ACLs and route tables.
   * Whether your workstation's public IP address has changed.

## 4. Prometheus Troubleshooting

### Problem: Prometheus container is restarting

Check container state and logs:

```bash
docker ps -a
docker logs enterprise-prometheus
```

If the container is running, validate `prometheus.yml` directly:

```bash
docker exec enterprise-prometheus \
  promtool check config /etc/prometheus/prometheus.yml
```

If the container exits immediately in a restart loop, validate the host configuration using a temporary container:

```bash
docker run --rm \
  --entrypoint promtool \
  -v "$PWD/monitoring/prometheus:/etc/prometheus:ro" \
  prom/prometheus:latest \
  check config /etc/prometheus/prometheus.yml
```

Correct any reported syntax or mount errors before restarting the service.

### Problem: Prometheus target shows `DOWN`

1. Open `http://localhost:9090/targets` and inspect the **Error** column for the failing target.
2. Test connectivity from the monitoring workstation:

   ```bash
   curl http://YOUR_EC2_PUBLIC_IP:9100/metrics
   ```

3. Verify the target IP and port in `monitoring/prometheus/prometheus.yml`.
4. After updating the configuration, validate and trigger a hot reload:

   ```bash
   docker exec enterprise-prometheus \
     promtool check config /etc/prometheus/prometheus.yml

   docker exec enterprise-prometheus \
     wget -qO- --post-data='' http://localhost:9090/-/reload
   ```

### Problem: Prometheus is not collecting metrics

Open the Prometheus expression browser at `http://localhost:9090` and query:

* `up` — Should return `1` for every healthy target.
* `node_cpu_seconds_total` — Confirms Node Exporter metrics are being ingested.

If no data is returned, check target health at `/targets`, scrape configuration in `prometheus.yml`, and host clock synchronization (`timedatectl`).

### Problem: Prometheus configuration reload fails

Validate the configuration and inspect Prometheus logs before retrying the reload:

```bash
docker exec enterprise-prometheus \
  promtool check config /etc/prometheus/prometheus.yml

docker logs enterprise-prometheus
```

*(Ensure Prometheus was started with `--web.enable-lifecycle` in `docker-compose.yml`; otherwise, restart the container via `docker compose -f monitoring/docker-compose.yml restart prometheus`.)*

## 5. Alert Rule Troubleshooting

### Problem: An alert remains `Pending`

Open `http://localhost:9090/alerts` and verify:

* Whether the PromQL expression returns a value.
* Whether the value exceeds the configured threshold.
* Whether the condition has remained true for the full `for:` duration (e.g., an alert with `for: 5m` stays `Pending` for five minutes before transitioning to `Firing`).
* Whether alert labels and metric selectors match active series.

### Problem: An alert does not fire

1. Run the alert's PromQL expression directly in `http://localhost:9090` (for example, CPU utilization):

   ```promql
   100 * (
     1 - avg by(instance) (
       rate(node_cpu_seconds_total{mode="idle"}[5m])
     )
   )
   ```

2. Validate all mounted rule files inside the container:

   ```bash
   for file in monitoring/prometheus/alerts/*.yml; do
       docker exec enterprise-prometheus \
         promtool check rules \
         "/etc/prometheus/alerts/$(basename "$file")" || break
   done
   ```

3. Confirm that `rule_files` in `prometheus.yml` matches the container mount path (`/etc/prometheus/alerts/*.yml`).

## 6. Grafana Troubleshooting

### Problem: Grafana is inaccessible

Check container status, logs, and the local health endpoint:

```bash
docker ps
docker logs enterprise-grafana
curl http://localhost:3000/api/health
```

Confirm that host port `3000` is bound to `127.0.0.1` in `docker-compose.yml`.

### Problem: Grafana cannot connect to Prometheus

Navigate to **Grafana → Connections → Data sources → Prometheus** and confirm the server URL is:

```text
http://prometheus:9090
```

> **Note:** Do not use `localhost:9090` as the data source URL—inside the Grafana container, `localhost` refers to the Grafana container itself rather than Prometheus.

Click **Save & test** to verify connectivity.

### Problem: Grafana dashboard displays `No data`

Check the following in order:

1. Prometheus data source connectivity (**Save & test**).
2. Target health at `http://localhost:9090/targets`.
3. The selected dashboard time range in the top-right corner of Grafana.
4. Whether the underlying PromQL query returns data directly in Prometheus (`http://localhost:9090`).

## 7. Alertmanager Troubleshooting

### Problem: Alertmanager container is restarting

Inspect container logs and validate `alertmanager.yml`:

```bash
docker logs enterprise-alertmanager

docker exec enterprise-alertmanager \
  amtool check-config /etc/alertmanager/alertmanager.yml
```

If the container is in a restart loop, validate using a temporary container:

```bash
docker run --rm \
  --entrypoint amtool \
  -v "$PWD/monitoring/alertmanager:/etc/alertmanager:ro" \
  prom/alertmanager:latest \
  check-config /etc/alertmanager/alertmanager.yml
```

Confirm that both `alertmanager.yml` and `secrets/smtp_password` are properly mounted in `docker-compose.yml`.

### Problem: Alerts are not reaching Alertmanager

Verify the `alerting` block in `monitoring/prometheus/prometheus.yml`:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "alertmanager:9093"
```

Confirm that `enterprise-alertmanager` is running on the same Docker network as Prometheus and inspect `docker logs enterprise-prometheus` for notification delivery errors.

### Problem: Alert routes do not match

Test `critical` and `warning` label routing with `amtool`:

```bash
docker exec enterprise-alertmanager \
  amtool config routes test \
  --config.file=/etc/alertmanager/alertmanager.yml \
  severity=critical

docker exec enterprise-alertmanager \
  amtool config routes test \
  --config.file=/etc/alertmanager/alertmanager.yml \
  severity=warning
```

Confirm that both commands resolve to the expected receiver (`email-alerts`).

## 8. Gmail SMTP Troubleshooting

### Problem: Email notifications are not delivered

Inspect Alertmanager logs first:

```bash
docker logs enterprise-alertmanager
```

Verify the following items without exposing credentials:

* **SMTP server & port:** `smtp.gmail.com:587` with TLS enabled (`smtp_require_tls: true`).
* **Authentication:** A valid **Gmail App Password** is used (not your standard Google account password).
* **Secret file:** Exists on the host and is readable inside the container:

  ```bash
  ls -l monitoring/alertmanager/secrets/
  stat monitoring/alertmanager/secrets/smtp_password
  ```

* **Recipient & inbox:** Verify the `to:` address in `alertmanager.yml` and check the recipient's Spam/Junk folder.

## 9. Docker Compose Troubleshooting

### Problem: A container is unhealthy

Inspect container statuses, health check output, and logs:

```bash
docker compose -f monitoring/docker-compose.yml ps
docker inspect --format='{{json .State.Health}}' enterprise-prometheus
docker logs CONTAINER_NAME
```

*(Replace `enterprise-prometheus` / `CONTAINER_NAME` with `enterprise-alertmanager` or `enterprise-grafana` as needed, and verify that the health-check utility—`wget` or `curl`—exists inside the image.)*

### Problem: Docker Compose configuration is invalid

Validate the Compose file syntax:

```bash
docker compose -f monitoring/docker-compose.yml config -q
```

If validation fails, inspect the reported YAML indentation, missing `.env` path, or volume mount error.

### Problem: Monitoring data disappears after container recreation

Verify that named volumes exist and are attached to the services:

```bash
docker volume ls
```

> **Warning:** Never run `docker compose down -v` unless you intentionally want to delete `prometheus_data`, `alertmanager_data`, and `grafana_data`.

## 10. Network Troubleshooting

Use these commands to verify listening ports, EC2 reachability, and local container health endpoints:

```bash
# Check listening ports on the host
sudo ss -tulnp

# Test Node Exporter locally (on EC2) and remotely (from workstation)
curl http://localhost:9100/metrics
curl http://YOUR_EC2_PUBLIC_IP:9100/metrics

# Test local monitoring container health endpoints
curl http://localhost:9090/-/healthy
curl http://localhost:9093/-/healthy
curl http://localhost:3000/api/health
```

*(Remember that Prometheus, Alertmanager, and Grafana ports are intentionally bound to `127.0.0.1`.)*

## 11. Troubleshooting Quick Reference

| Component | Diagnostic Command / Endpoint | Main Purpose |
| :--- | :--- | :--- |
| **Node Exporter** | `sudo systemctl status node_exporter` | Check service health |
| **Node Exporter** | `sudo journalctl -u node_exporter -n 50` | Inspect service logs |
| **Prometheus** | `promtool check config /etc/prometheus/prometheus.yml` | Validate configuration syntax |
| **Prometheus** | `http://localhost:9090/targets` | Inspect target scrape health and errors |
| **Prometheus** | `http://localhost:9090/alerts` | Inspect alert rule states (`Pending` / `Firing`) |
| **Grafana** | `docker logs enterprise-grafana` | Inspect Grafana application logs |
| **Alertmanager** | `amtool check-config /etc/alertmanager/alertmanager.yml` | Validate Alertmanager configuration |
| **Docker Compose** | `docker compose -f monitoring/docker-compose.yml ps` | Inspect container health status |
| **Docker** | `docker logs CONTAINER_NAME` | Inspect individual container logs |

## 12. Conclusion

Effective monitoring relies on repeatable diagnostics—isolating the failing layer, inspecting logs, validating configuration syntax before reloading, and verifying end-to-end recovery. Together with the architecture and deployment guides, this troubleshooting reference completes the operational documentation for the `enterprise-linux-server-deployment` monitoring stack.