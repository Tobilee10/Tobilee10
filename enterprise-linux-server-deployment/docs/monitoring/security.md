# Monitoring Infrastructure Security Guide

## 1. Introduction

Security is essential to infrastructure monitoring because telemetry and management interfaces expose sensitive operational details about hosts, network interfaces, system resources, and alert routing.

In the `enterprise-linux-server-deployment` project, security controls are applied across the managed AWS EC2 Linux server, the containerized monitoring stack on the local Linux workstation, network access paths, credential storage, and Git repository hygiene.

## 2. Security Architecture

The monitoring environment spans an **AWS EC2 Ubuntu managed server** running **Node Exporter**, a local Linux workstation running **Prometheus**, **Grafana**, and **Alertmanager** via Docker Compose, and **Gmail SMTP** for email alerts.

Security is structured across six layers:

1. **Linux host security:** Dedicated unprivileged service user and `systemd` hardening.
2. **Network access restrictions:** `/32` source IP filtering on AWS Security Groups and loopback port bindings.
3. **Docker container security:** Trusted images, read-only mounts, health checks, and least-privilege port publishing.
4. **Credential and secret management:** Externalized environment and secret files with restrictive permissions.
5. **Monitoring service access control:** Loopback-only web bindings and secure remote access methods.
6. **Git repository protection:** `.gitignore` rules, `.example` templates, and pre-commit/history checks.

## 3. Network Security

### 3.1 Restricting Node Exporter Access

Node Exporter listens on TCP port `9100` and exposes host-level system and resource metrics over HTTP. Configure the EC2 Security Group to allow inbound TCP port `9100` strictly from your trusted monitoring workstation's public IP using a `/32` CIDR:

```text
Protocol: TCP
Port:     9100
Source:   YOUR_TRUSTED_PUBLIC_IP/32
```

> **Security Rule:** Never expose Node Exporter port `9100` to `0.0.0.0/0`.

### 3.2 Monitoring Service Port Binding

Bind Prometheus, Grafana, and Alertmanager host ports exclusively to the local loopback interface (`127.0.0.1`) so they are not exposed on external network interfaces:

| Service | Port | Host Binding |
| :--- | ---: | :--- |
| **Prometheus** | `9090` | `127.0.0.1` |
| **Grafana** | `3000` | `127.0.0.1` |
| **Alertmanager** | `9093` | `127.0.0.1` |

Example Docker Compose port mapping:

```yaml
ports:
  - "127.0.0.1:9090:9090"
```

For remote administration, use an encrypted SSH tunnel, VPN, or authenticated reverse proxy rather than opening these ports publicly.

## 4. Linux User and Service Security

Run Node Exporter under a dedicated non-login system account (`node_exporter`) rather than `root` or an interactive user:

```bash
sudo useradd \
  --system \
  --no-create-home \
  --shell /usr/sbin/nologin \
  node_exporter
```

### Systemd Hardening Directives

Configure the `systemd` unit with process restrictions to limit blast radius if the exporter process is ever compromised:

```ini
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
```

Inspect and verify the service configuration and status:

```bash
sudo systemctl status node_exporter --no-pager
sudo systemctl cat node_exporter
```

## 5. Docker Security

Follow core container security practices when operating the Docker Compose monitoring stack:

* Use trusted container images and review logs regularly for unexpected behavior.
* Publish only necessary ports bound to `127.0.0.1` and avoid `--privileged` mode.
* Avoid mounting sensitive host directories unnecessarily; mount configuration and secret files read-only where appropriate.
* Keep container images updated and use named Docker volumes for persistent application data.
* Restrict access to the Docker daemon to trusted administrators, as Docker access carries high privilege.

Verify running containers and published port bindings:

```bash
docker ps
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

## 6. Credential and Secret Management

Keep administrator credentials and SMTP secrets out of Git and public documentation, specifically:

* `monitoring/grafana/.env`
* `monitoring/alertmanager/secrets/smtp_password`

### 6.1 Grafana Credentials

Supply Grafana administrator credentials through `monitoring/grafana/.env` (excluded from Git). Never publish real usernames or passwords in documentation or source control.

### 6.2 Alertmanager SMTP Credentials

Reference the SMTP password via file rather than embedding it inline in `alertmanager.yml`:

```yaml
smtp_auth_password_file: /etc/alertmanager/secrets/smtp_password
```

The secret file is mounted read-only into the Alertmanager container.

### 6.3 File Permissions and Container Read Access

Inspect and restrict permissions on sensitive secret files:

```bash
ls -l monitoring/alertmanager/secrets/
chmod 400 monitoring/alertmanager/secrets/smtp_password
```

> **Ownership Note:** When tightening permissions (such as `chmod 400`), ensure file ownership or group permissions still allow the non-root container process (e.g., the Alertmanager user/UID) to read the mounted secret file without permission errors.

### 6.4 Credential Protection Practices

* Use a **Gmail App Password** rather than your standard Google account password.
* Never place real passwords in public YAML files or documentation.
* Rotate credentials immediately if exposed, and consider a dedicated secrets manager as the environment scales.

## 7. Git Repository Security

Exclude sensitive files and local backups using `.gitignore`:

```gitignore
.env
.env.*
!.env.example
monitoring/grafana/.env
monitoring/alertmanager/secrets/
monitoring/prometheus/prometheus.yml.backup
```

Verify that sensitive paths are ignored and not tracked in Git:

```bash
git check-ignore -v monitoring/grafana/.env
git check-ignore -v monitoring/alertmanager/secrets/smtp_password

git ls-files monitoring/grafana/.env
git ls-files monitoring/alertmanager/secrets/smtp_password
```

An empty output from `git ls-files` indicates the file is not tracked.

> **Important:** `.gitignore` does not remove previously committed files or scrub Git history. If a secret was ever committed, rotate it immediately and clean repository history before publishing.

## 8. Prometheus and Alertmanager Access

Prometheus and Alertmanager expose operational and alert state details and should never be left reachable on untrusted networks. Keep their host bindings on `127.0.0.1` (see [Section 3.2](#32-monitoring-service-port-binding)) and use SSH port forwarding, a VPN, a private network, or an authenticated reverse proxy for remote access.

## 9. Grafana Access Security

Protect Grafana dashboards and metrics views with strong access hygiene:

* Use a strong, unique administrator password and never share admin credentials.
* Provision individual accounts where multiple users need access and apply least-privilege roles and folder/dashboard permissions.
* Enforce HTTPS when exposing Grafana remotely and audit user access periodically.

## 10. Node Exporter Security Limitations

By default, Node Exporter serves HTTP metrics without transport encryption or authentication, relying here on AWS Security Group `/32` source restriction on TCP port `9100`. While suitable for a controlled lab deployment, production environments should evaluate:

* TLS and/or authentication on the exporter/scrape path.
* Private networking or a VPN between scraper and target.
* Defense-in-depth host and network firewall controls.

## 11. Security Verification Checklist

Use this checklist during security reviews and deployments:

* [ ] Node Exporter runs under a dedicated non-login account (`node_exporter`) with `systemd` hardening.
* [ ] EC2 Security Group restricts inbound TCP `9100` to the trusted workstation's `/32` IP.
* [ ] Prometheus (`9090`), Grafana (`3000`), and Alertmanager (`9093`) bind to `127.0.0.1`.
* [ ] Sensitive `.env` and secret files are excluded by `.gitignore` and untracked in Git.
* [ ] Alertmanager SMTP password is stored in a mounted secret file with restrictive permissions readable by the container.
* [ ] Docker daemon access is restricted to trusted administrators and no real credentials appear in docs or Git.

## 12. Security Limitations and Future Improvements

This setup is a practical monitoring lab and portfolio implementation rather than a fully hardened enterprise platform. Future security enhancements include:

* Enabling TLS and authentication for Node Exporter and HTTPS for remote web access.
* Hosting monitoring components on a dedicated private server with centralized secrets management and RBAC.
* Pinning container images to tested versions or digests, adding vulnerability scanning, and automating safe updates.
* Implementing encrypted off-host backups and independent external availability monitoring.

## 13. Conclusion

Layered security controls—spanning Linux `systemd` hardening, `/32` network restrictions, loopback port bindings, secret file isolation, and Git hygiene—help protect monitoring infrastructure and credentials as the deployment grows.