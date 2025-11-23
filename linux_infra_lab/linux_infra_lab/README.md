# Linux Infrastructure Lab – Multi-Node Systems Project

This lab is a small, realistic multi-node Linux environment designed for practicing systems administration, 
networking, containerization, and basic service management. It is intended as a personal learning lab and 
portfolio project.

## Lab Topology

The lab assumes three virtual machines on a private network:

- **mgmt-node**: Jump host / management node (Ubuntu)
- **app-node**: Application node running a containerized web app (Ubuntu)
- **db-node**: Backend/data node (Ubuntu or Rocky Linux)

Example IP plan (adjust to your environment):

- mgmt-node: `10.10.10.10`
- app-node: `10.10.10.20`
- db-node: `10.10.10.30`
- Netmask: `255.255.255.0`
- Gateway: your host or a NAT adapter, depending on your virtualization setup

## Prerequisites

- A hypervisor (VirtualBox, VMware, or similar)
- Linux ISO images (Ubuntu Server or Rocky Linux)
- Basic familiarity with:
  - SSH
  - Editing configuration files with `vim` or `nano`
  - Running shell scripts with `bash`

## Repository Layout

```text
linux_infra_lab/
├── README.md
├── scripts/
│   ├── bootstrap_common.sh
│   ├── create_lab_user.sh
│   ├── harden_ssh.sh
│   └── install_demo_service.sh
├── docker/
│   └── docker-compose.yml
└── config/
    └── myapp_logrotate
```

- `scripts/bootstrap_common.sh` – Base packages, log directory, basic tooling
- `scripts/create_lab_user.sh` – Creates a non-root admin user and sets up SSH access
- `scripts/harden_ssh.sh` – Applies simple SSH hardening and UFW rules
- `scripts/install_demo_service.sh` – Installs and enables a simple demo systemd service
- `docker/docker-compose.yml` – Simple multi-container test stack (web + db)
- `config/myapp_logrotate` – Logrotate config for the demo service logs

> **Note:** All scripts are written to be run on each VM as needed. Review and adjust the scripts before running 
them in your own environment.

## Step 1: Create the Virtual Machines

1. Create three VMs and install Ubuntu Server or Rocky Linux.
2. Configure a host-only or internal network so the VMs can reach each other.
3. Assign static IPs according to your chosen IP plan.

On Ubuntu, static IPs are typically configured in `/etc/netplan/*.yaml`. For example:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      addresses:
        - 10.10.10.10/24
      gateway4: 10.10.10.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

Apply with:

```bash
sudo netplan apply
```

## Step 2: Bootstrap Each Node

Copy the `scripts/` and `config/` directories to each VM (for example with `scp`), then on each node:

```bash
cd ~/linux_infra_lab/scripts
sudo bash bootstrap_common.sh
```

This will:

- Update package indexes
- Install basic tools (`curl`, `vim`, `git`, `ufw`, etc.)
- Create a `/var/log/myapp` directory for the demo service

## Step 3: Create a Lab Admin User

On each node, run:

```bash
sudo bash create_lab_user.sh labadmin
```

This will:

- Create a `labadmin` user (or any name you pass)
- Add the user to the `sudo` group
- Optionally add the user to the `docker` group if Docker is available

You can then SSH into the node as the new user instead of using `root`.

## Step 4: Harden SSH and Configure UFW

On each node:

```bash
sudo bash harden_ssh.sh labadmin
```

This will:

- Backup `/etc/ssh/sshd_config`
- Disable root login
- Restrict SSH login to the specified user
- Enable UFW and allow SSH and HTTP

Restart SSH afterward:

```bash
sudo systemctl restart sshd
```

## Step 5: Install the Demo Systemd Service

On the node where you want to run the example service (usually `app-node`):

```bash
sudo bash install_demo_service.sh
```

This will:

- Install `/usr/local/bin/myapp_demo.sh`
- Install `/etc/systemd/system/myapp_demo.service`
- Enable and start the service
- Register a logrotate config for `/var/log/myapp/myapp_demo.log`

You can verify it is running:

```bash
systemctl status myapp_demo.service
tail -f /var/log/myapp/myapp_demo.log
```

## Step 6: Deploy the Docker Demo Stack (app-node)

On `app-node`, ensure Docker is installed (on Ubuntu you can use the convenience script or the official docs).

In the `docker/` directory:

```bash
cd docker
docker compose up -d
```

This will start:

- A simple NGINX web server
- A Postgres database
- A tiny "whoami" HTTP service for testing

You can test locally:

```bash
curl http://localhost:8080
curl http://localhost:8081
```

## Verification Checklist

- [ ] All three VMs can ping each other by IP
- [ ] SSH access works only for the non-root admin user
- [ ] UFW is active and only allows expected ports
- [ ] `myapp_demo.service` is running and logging to `/var/log/myapp/myapp_demo.log`
- [ ] `docker compose ps` shows the demo containers as healthy

## Notes

- This lab is intentionally small and simple; you can expand it with:
  - Ansible playbooks
  - Additional services
  - Monitoring tools like `prometheus` and `node_exporter`
- Always review the scripts and configuration files to understand what they do before running them
