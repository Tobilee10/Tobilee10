# Alerting and Notifications Guide

## 1. Introduction

Alerting is a key part of infrastructure monitoring, helping administrators detect problems before they escalate into major service disruptions.

In the `enterprise-linux-server-deployment` project, **Prometheus** evaluates alert rules against collected metrics while **Alertmanager** manages grouping, routing, and notification delivery through **Gmail SMTP**, covering:

* **CPU utilization**

* **Memory utilization**

* **Disk utilization**

* **Network traffic**

* **Node Exporter availability**

* **Prometheus target health**

## 2. Alerting Architecture

```text
AWS EC2 Ubuntu Server
        |
        v
Node Exporter (:9100)
        |
        v
Prometheus (:9090)
        |
        | Evaluates alert rules
        v
Alert Rules
        |
        | Sends firing & resolved alerts
        v
Alertmanager (:9093)
        |
        | SMTP (port 587 / TLS)
        v
Gmail SMTP
        |
        v
Email Notifications
```

### Component Responsibilities

| Component | Responsibility |
| :--- | :--- |
| **Node Exporter** | Exposes Linux host metrics over HTTP on port `9100` |
| **Prometheus** | Scrapes metrics and evaluates alert rules at configured intervals |
| **Alert rules** | Define PromQL conditions, durations, labels, and annotations |
| **Alertmanager** | Groups, routes, deduplicates, and manages notification lifecycle |
| **Gmail SMTP** | Delivers email notifications to configured recipients |

## 3. Prometheus Alert Rules

Alert rule files are stored on the host under `monitoring/prometheus/alerts/` and mounted into the Prometheus container at `/etc/prometheus/alerts/`:

```yaml
rule_files:
  - "/etc/prometheus/alerts/*.yml"
```

### Alert Rule Files

| File | Purpose |
| :--- | :--- |
| `availability-alerts.yml` | Monitors Node Exporter availability and missing targets |
| `cpu-alerts.yml` | Monitors CPU utilization |
| `disk-alerts.yml` | Monitors filesystem / disk utilization |
| `memory-alerts.yml` | Monitors memory utilization |
| `network-alerts.yml` | Monitors incoming and outgoing network traffic |
| `prometheus-alerts.yml` | Monitors Prometheus self-scrape targets and scrape conditions |

## 4. Understanding Alert Rule Structure

A typical Prometheus alert rule definition follows this structure:

```yaml
groups:
  - name: cpu-alerts
    rules:
      - alert: HighCPUUtilization
        expr: |
          100 * (
            1 - avg by(instance) (
              rate(node_cpu_seconds_total{mode="idle"}[5m])
            )
          ) > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High CPU utilization detected
          description: CPU utilization has remained above 85% for five minutes.
```

| Field | Meaning |
| :--- | :--- |
| `groups` | Organizes related alert rules into named groups |
| `name` | Identifies the rule group |
| `alert` | Defines the alert name emitted when firing |
| `expr` | PromQL expression evaluated by Prometheus each `evaluation_interval` |
| `for` | Duration `expr` must stay true before transitioning from `Pending` to `Firing` |
| `labels` | Adds metadata labels (such as `severity`) used for routing and grouping |
| `annotations` | Provides human-readable summary and description details |

Using a `for` duration prevents brief, transient spikes from generating unnecessary alerts.

## 5. Configured Alert Conditions

The table below reflects the baseline alert policies for this project (verify local rule YAML files directly before modifying):

| Alert | Condition | Duration | Severity |
| :--- | :--- | :--- | :--- |
| `HighCPUUtilization` | CPU utilization above `85%` | `5m` | `warning` |
| `HighMemoryUtilization` | Memory utilization above `85%` | `5m` | `warning` |
| `HighDiskUtilization` | Root disk utilization above `80%` | `5m` | `warning` |
| `HighNetworkReceive` | Receive traffic above `10 MiB/s` | `5m` | `warning` |
| `HighNetworkTransmit` | Transmit traffic above `10 MiB/s` | `5m` | `warning` |
| `NodeExporterDown` | Managed server target is down (`up == 0`) | `2m` | `critical` |
| `PrometheusTargetMissing` | Managed server target series is absent | `2m` | `critical` |
| `PrometheusTargetDown` | Prometheus self-monitoring target is down | `2m` | `critical` |
| `PrometheusScrapeFailures` | Scrape sample-limit exceedance counter increases | `2m` | `warning` |

### Important Considerations

* Thresholds are starting baselines, not universal production standards—tune CPU, memory, and network limits to match actual workloads.

* `PrometheusScrapeFailures` specifically detects sample-limit exceedances rather than every possible scrape error.

* Prometheus cannot evaluate rules or send alerts if the Prometheus process or monitoring workstation itself goes offline.

## 6. Understanding Prometheus Alert States

Alerts transition through three primary states:

* **`Inactive`:** The alert expression is not currently true, and no active alert condition exists.

* **`Pending`:** The alert expression is true, but the configured `for` duration has not yet elapsed.

* **`Firing`:** The condition has remained true for the full `for` duration; Prometheus forwards the alert to Alertmanager, and sends a resolved notification once the condition clears.

```text
Condition true (expr > threshold)
        |
        v
     Pending  ──[clears before "for" elapses]──> Inactive
        |
        | Condition remains true for "for" duration
        v
     Firing   ──[Alertmanager sends firing email]
        |
        | Condition clears
        v
    Inactive  ──[Alertmanager sends resolved email]
```

## 7. Validating Prometheus Alert Rules

Validate rule syntax and structure before reloading Prometheus:

```bash
for file in monitoring/prometheus/alerts/*.yml; do
    echo "Checking: $file"
    docker exec enterprise-prometheus \
      promtool check rules \
      "/etc/prometheus/alerts/$(basename "$file")" \
      || break
done
```

`promtool check rules` verifies syntax and schema structure—always test PromQL expressions against live data as well. Inspect loaded rules and active alert states in the Prometheus UI at `http://localhost:9090/rules` and `http://localhost:9090/alerts`.

## 8. Alertmanager Configuration

Alertmanager configuration lives at `monitoring/alertmanager/alertmanager.yml`. Prometheus connects to Alertmanager over the shared Docker Compose network using internal DNS:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - "alertmanager:9093"
```

## 9. Alertmanager Routing

Alertmanager groups and routes alerts based on labels (`severity: critical` and `severity: warning`). Both severity routes use the `email-alerts` receiver with different notification timing:

```yaml
route:
  receiver: email-alerts
  group_by:
    - alertname
    - instance
    - severity
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    - matchers:
        - severity="critical"
      receiver: email-alerts
      group_wait: 10s
      repeat_interval: 1h

    - matchers:
        - severity="warning"
      receiver: email-alerts
      group_wait: 30s
      repeat_interval: 4h
```

| Setting | Purpose |
| :--- | :--- |
| `receiver` | Default notification destination (`email-alerts`) |
| `group_by` | Groups alerts sharing matching label values |
| `group_wait` | Initial delay before sending the first notification for a new alert group |
| `group_interval` | Delay before sending notifications for new alerts added to an existing group |
| `repeat_interval` | How often a still-firing alert group re-sends a reminder notification |

## 10. Gmail SMTP Integration

Alertmanager sends email notifications via Gmail SMTP on port `587` with TLS enabled (`smtp.gmail.com:587`).

### Credential Management

Store the **Gmail App Password** in `monitoring/alertmanager/secrets/smtp_password`, mounted read-only into the container and referenced in `alertmanager.yml`:

```yaml
smtp_auth_password_file: /etc/alertmanager/secrets/smtp_password
```

* Use a **Gmail App Password**, not your standard Google account password.

* Never commit `smtp_password` or any secrets to Git or public documentation.

* Keep file permissions restrictive and rotate credentials immediately if ever exposed.

## 11. Alertmanager Email Receiver

Configure the `email-alerts` receiver with `send_resolved: true` so recovery emails are sent when alerts clear:

```yaml
receivers:
  - name: "email-alerts"
    email_configs:
      - to: "YOUR_NOTIFICATION_EMAIL"
        send_resolved: true
```

Keep real recipient email addresses in your private configuration file rather than public documentation.

## 12. Validating Alertmanager Configuration

Validate `alertmanager.yml` and test `critical` and `warning` route resolution using `amtool`:

```bash
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

Both route tests should resolve to `email-alerts`.

## 13. Testing Email Notifications

Syntax validation does not confirm SMTP delivery—verify the full pipeline with a controlled test:

1. Confirm Prometheus can reach Alertmanager and the target alert rule is loaded.

2. Trigger a controlled test condition (or temporary test threshold) and watch the alert move from `Pending` to `Firing` at `http://localhost:9090/alerts`.

3. Check active alerts in Alertmanager at `http://localhost:9093` and confirm the firing email arrives.

4. Clear the test condition and confirm a resolved email arrives (`send_resolved: true`).

Avoid causing disruptive resource exhaustion on production servers when testing alerts.

## 14. Troubleshooting

| Issue | Diagnostic Commands & Checks |
| :--- | :--- |
| **Prometheus not sending alerts** | Inspect `docker logs enterprise-prometheus`; verify rules are loaded, PromQL returns expected values, configuration is valid, and `alertmanager:9093` is reachable. |
| **Alertmanager restarting** | Inspect `docker logs enterprise-alertmanager`, run `amtool check-config`, and verify `alertmanager.yml` and `secrets/smtp_password` mounts. |
| **Emails not arriving** | Check `docker logs enterprise-alertmanager`; verify `smtp.gmail.com:587`, TLS, Gmail App Password, secret file permissions/mount, recipient address, and Spam/Junk folder. |
| **Alert stuck in `Pending`** | Verify the `for` duration has elapsed, the metric exists, and the expression remains true across evaluations. |
| **Alert `Firing` but no email** | Check Alertmanager UI (`http://localhost:9093`), label matchers (`severity`), receiver configuration, SMTP authentication, and Alertmanager logs. |

## 15. Monitoring Limitations and Future Improvements

### Operational Limitations

* Runs on a single local Linux workstation that must remain powered on and connected to the internet.

* Cannot self-notify if the Prometheus process or local workstation itself goes down.

* Relies on external Gmail SMTP availability and baseline thresholds that should be tuned to workload traffic.

### Future Improvements

* Deploy the monitoring stack on a dedicated, always-on server and add independent external availability monitoring.

* Implement automated backups and recovery procedures for configurations and persistent volumes.

* Expand to application-level metrics, escalation policies, and additional notification channels.

## 16. Conclusion

This alerting workflow connects **Node Exporter**, **Prometheus**, **Alertmanager**, and **Gmail SMTP** to detect resource pressure and target availability issues early, support controlled alert testing and recovery verification, and keep sensitive credentials out of version control.