# linux-infrastructure-lab

Two Ubuntu 24.04 VMs deployed on Azure using Terraform. All VMs Linux configurations, networking, storage, services, security and identity management are configured manually. The Gateway VM acts as a reverse proxy, firewall, and NAT gateway. The Backend VM runs storage, databases, and internal services.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Azure VNET: 10.0.0.0/16                                        │
│                                                                 │
│  ┌──────────────────────────┐   ┌─────────────────────────────┐ │
│  │  snet-gateway            │   │  snet-backend               │ │
│  │  10.0.1.0/24             │   │  10.0.2.0/24                │ │
│  │                          │   │                             │ │
│  │  ┌────────────────────┐  │   │  ┌───────────────────────┐  │ │
│  │  │  gateway           │  │   │  │  backend              │  │ │
│  │  │  10.0.1.10         │  │   │  │  10.0.2.11            │  │ │
│  │  │                    │  │   │  │                       │  │ │
│  │  │  Nginx (reverse    │  │   │  │  MariaDB              │  │ │
│  │  │    proxy + SSL)    │  │   │  │  NFS Server           │  │ │
│  │  │  UFW + iptables    │  │   │  │  LVM (3x5GB disks)    │  │ │
│  │  │  NAT/MASQUERADE    │  │   │  │  Health Check Service │  │ │
│  │  │  SSH (port 2222)   │  │   │  │  Docker               │  │ │
│  │  │  AppArmor          │  │   │  │  LDAP Server          │  │ │
│  │  │  NFS Client/Autofs │  │   │  │  AppArmor             │  │ │
│  │  │  LDAP Client(SSSD) │  │   │  │  Cron + Timers        │  │ │
│  │  └────────────────────┘  │   │  └───────────────────────┘  │ │
│  └──────────────────────────┘   └─────────────────────────────┘ │
│                                                                 │
│  Route Table: 0.0.0.0/0 → 10.0.1.10 (on snet-backend)           │
│  NSG: SSH from admin IP, HTTP/HTTPS public, inter-subnet open   │
└─────────────────────────────────────────────────────────────────┘
```

**Traffic flow:** Internet → gateway public IP → Nginx (HTTPS/443) → proxy_pass → backend:8080. Backend reaches the internet through gateway via Azure UDR + iptables MASQUERADE. SSH access to backend is via ProxyJump through gateway on port 2222.

## Configurations

### Networking

| Area | Where | Config Files |
|---|---|---|
| Static IP configuration (netplan) | Both | `*/etc/netplan/50-cloud-init.yaml` |
| Hostname resolution | Both | `*/etc/hosts` |
| NTP time synchronization | Both | `*/etc/chrony/chrony.conf` |
| SSH hardening + non-standard port | Both | `*/etc/ssh/sshd_config`, `gateway/etc/systemd/system/ssh.socket.d/override.conf` |
| Packet filtering (UFW) | Gateway | `gateway/state/ufw-status.txt` |
| NAT + MASQUERADE (iptables) | Gateway | `gateway/etc/iptables/rules.v4` |
| IP forwarding | Gateway | `gateway/etc/sysctl.d/ip-forward.conf` |
| Reverse proxy + load balancing | Gateway | `gateway/etc/nginx/conf.d/reverse-proxy.conf` |
| SSL/TLS termination | Gateway | `gateway/etc/ssl/certs/server.crt`, `gateway/etc/nginx/conf.d/reverse-proxy.conf` |
| Bridge and bonding | Gateway | Demonstrated with dummy interfaces, torn down after verification |

### Storage

| Area | Where | Config Files |
|---|---|---|
| LVM (PV → VG → LV, online extend) | Backend | `backend/state/lvm.txt`, `backend/state/lsblk.txt` |
| Filesystems (ext4, xfs) | Backend | `backend/etc/fstab` |
| Persistent mounts with UUID | Backend | `backend/etc/fstab` |
| NFS server + client | Both | `backend/etc/exports`, `gateway/etc/auto.master`, `gateway/etc/auto.nfs` |
| Autofs on-demand mounting | Gateway | `gateway/etc/auto.master`, `gateway/etc/auto.nfs` |
| Swap configuration | Backend | `backend/etc/fstab`, `backend/state/swaps.txt` |

### Services and Automation

| Area | Where | Config Files |
|---|---|---|
| Custom systemd service (oneshot) | Backend | `backend/etc/systemd/system/health-check.service` |
| Systemd timer scheduling | Backend | `backend/etc/systemd/system/health-check.timer` |
| Cron jobs (user + system-wide) | Backend | `backend/etc/cron.d/disk-report`, `backend/state/crontab-dev1.txt` |
| MariaDB (network-bound) | Backend | `backend/etc/mysql/mariadb.conf.d/50-server.cnf` |
| Docker containers | Backend | Images pulled, port-mapped, volumes mounted, Dockerfile built |
| Health monitoring script | Backend | `backend/scripts/health-check.sh` |

### Users, Groups, and Security

| Area | Where | Config Files |
|---|---|---|
| Users and groups (primary + supplementary) | Backend | `backend/state/users.txt`, `backend/state/groups.txt` |
| System-wide environment profiles | Backend | `backend/etc/profile.d/custom.sh` |
| Resource limits (limits.conf) | Backend | `backend/etc/security/limits.conf` |
| ACLs, SGID, sticky bit | Backend | Set on `/opt/projects`, `/opt/logs`, `/opt/shared` |
| AppArmor (enforce + custom profiles) | Both | `gateway/etc/apparmor.d/usr.sbin.nginx`, `backend/etc/apparmor.d/opt.scripts.health-check.sh` |
| LDAP client (SSSD) | Gateway | `gateway/etc/sssd/sssd.conf`, `gateway/etc/nsswitch.conf` |
| Kernel parameters (persistent) | Both | `*/etc/sysctl.d/ip-forward.conf`, `backend/etc/sysctl.d/swappiness.conf` |

## Repository Structure

```
linux-infrastructure-lab/
├── terraform/
│   ├── main/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tf        
│   └── modules/
│       ├── networking/         
│       └── vm/                
├── gateway/
│   ├── etc/                    
│   │   ├── nginx/conf.d/       
│   │   ├── ssh/                
│   │   ├── netplan/            
│   │   ├── iptables/           
│   │   ├── sysctl.d/          
│   │   ├── sssd/              
│   │   └── ssl/certs/          
│   └── state/                  
├── backend/
│   ├── etc/                    
│   │   ├── systemd/system/
│   │   ├── security/           
│   │   ├── mysql/
│   │   ├── sysctl.d/           
│   │   └── cron.d/
│   ├── scripts/
│   │   └── health-check.sh
│   └── state/                  
├── scripts/
│   └── bootstrap.sh
└── README.md
```

## Azure Infrastructure

Provisioned with Terraform.

| Resource | Name | Purpose |
|---|---|---|
| Resource Group | rg-lfcs-lab | All resources |
| VNET | vnet-lfcs-lab (10.0.0.0/16) | Network isolation |
| Subnet | snet-gateway (10.0.1.0/24) | DMZ — public-facing |
| Subnet | snet-backend (10.0.2.0/24) | Internal — no direct internet |
| Route Table | rt-backend | Forces backend traffic through gateway |
| NSG | nsg-gateway | SSH (2222), HTTP, HTTPS, backend subnet |
| NSG | nsg-backend | SSH from admin IP, all from gateway subnet |
| VM | vm-gateway (Standard_B2s_v2) | Reverse proxy, firewall, jump host |
| VM | vm-backend (Standard_B2s_v2) | Storage, services, database |
| Disks | 3x5GB + 1x10GB on backend | LVM practice + NFS share |

## Key Decisions

**Two-layer networking:** Azure NSGs filter traffic at the Azure level. UFW and iptables handle filtering inside the VMs. Both layers need to allow the required traffic.

**UDR over OS routing:** The Backend VM uses Azure's gateway (10.0.2.1) as its default route. A User Defined Route redirects outbound traffic through the Gateway VM at 10.0.1.10. Using both UDR and a custom OS route caused conflicts, so routing is handled by the UDR only.

**SSH port 2222 with socket activation:** Ubuntu 24.04 uses systemd socket activation for SSH. The listening port is configured in /etc/systemd/system/ssh.socket.d/override.conf.

**cloud-init disabled for networking:** `99-disable-network-config.cfg` prevents cloud-init from overwriting the Netplan configuration after reboot. This keeps the static IP and DNS settings in place.