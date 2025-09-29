# Windows Server 2019 - Complete WebSphere ND Deployment Pipeline

## Project Overview

This project provides a complete infrastructure pipeline for WebSphere Application Server Network Deployment:
1. **Packer Template**: Creates a Windows Server 2019 VM template in vSphere
2. **Terraform Configuration**: Deploys VMs from the template and joins them to an existing Active Directory domain
3. **Ansible WebSphere ND**: Installs and configures WebSphere Application Server Network Deployment

**Important**: This project does NOT create an Active Directory domain. It assumes an existing AD domain is available and joins new Windows servers to it.

## Architecture Flow

```
1. Packer builds Windows 2019 template → vSphere Template
2. Terraform uses template → Creates VM(s) → Joins existing AD domain
3. Ansible installs WebSphere ND → DMGR + App Servers → Production Ready
```

## WebSphere ND Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   WebSphere-1   │    │   WebSphere-2   │    │   WebSphere-3   │
│  (DMGR Server)  │    │ (App Server 1)  │    │ (App Server 2)  │
│                 │    │                 │    │                 │
│ • Admin Console │    │ • Node Agent    │    │ • Node Agent    │
│ • Cell Manager  │    │ • App Server    │    │ • App Server    │
│ • LDAP Config   │    │ • Applications  │    │ • Applications  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## PACKER CONFIGURATION

### Required Variables (credentials.json)

| Variable | Description | Example |
|----------|-------------|---------|
| `vsphere-server` | vCenter server FQDN/IP | `vcenter.company.com` |
| `vsphere-user` | vCenter username | `administrator@vsphere.local` |
| `vsphere-password` | vCenter password | `SecurePassword123` |
| `vsphere-datacenter` | Target datacenter | `Datacenter` |
| `vsphere-cluster` | Target cluster | `Production-Cluster` |
| `vsphere-network` | VM network | `VM Network` |
| `vsphere-datastore` | Target datastore | `Datastore1` |
| `vsphere-folder` | Template folder | `Templates` |
| `vm-name` | Template name | `Win2019-Template-Base` |
| `vm-cpu-num` | CPU count | `2` |
| `vm-mem-size` | Memory in MB | `4096` |
| `os-disk-size` | Disk size in MB | `40960` |
| `disk-thin-provision` | Thin provisioning | `true` |
| `winadmin-password` | Local admin password | `S3cr3t0!` |
| `os_iso_path` | Windows ISO path | `[datastore] ISO/windows2019.iso` |

### Packer Output
- **Template Name**: Value of `vm-name` variable
- **Location**: vSphere datacenter specified in `vsphere-folder`
- **Credentials**: Administrator / `winadmin-password`

### Build Command
```bash
packer build -var-file="credentials.json" windows2019.json
```

---

## TERRAFORM CONFIGURATION

### Required Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `vsphere_user` | string | vCenter username | `administrator@vsphere.local` |
| `vsphere_password` | string | vCenter password | `SecurePassword123` |
| `vsphere_server` | string | vCenter server | `vcenter.company.com` |
| `windows_template` | string | Packer template name | `Win2019-Template-Base` |
| `vm-name` | string | VM name prefix | `WebServer` |
| `vm-count` | number | Number of VMs | `2` |
| `vm-cpu` | string | CPU count | `2` |
| `vm-ram` | string | Memory in MB | `4096` |
| `domain` | string | **Existing AD domain** | `company.local` |
| `domain_admin_user` | string | Domain admin username | `domainadmin` |
| `domain_admin_password` | string | Domain admin password | `DomainPassword123` |
| `dns_server_list` | list | DNS servers | `["192.168.1.10", "192.168.1.11"]` |
| `ipv4_addresses` | list | Static IP addresses | `["192.168.1.100", "192.168.1.101"]` |
| `ipv4_netmasks` | list | Subnet masks | `[24, 24]` |
| `vmgateway` | string | Network gateway | `192.168.1.1` |
| `local_adminpass` | string | Local admin password | `LocalAdmin123` |

### Computer Naming Convention

VMs are automatically named using the pattern: `${vm-name}-${count.index + 1}`

**Examples:**
- If `vm-name = "WebServer"` and `vm-count = 3`
- Results: `WebServer-1`, `WebServer-2`, `WebServer-3`

### Terraform Outputs

| Output | Description |
|--------|-------------|
| `ipv4` | Map of VM names to IPv4 addresses |
| `ipv6` | Map of VM names to IPv6 addresses |

### Deploy Command
```bash
cd terraform-windows-join-ad-domain
terraform init
terraform plan
terraform apply
```

---

## DOMAIN REQUIREMENTS

### Prerequisites
- **Existing Active Directory domain must be running**
- Domain controller accessible from target network
- DNS properly configured
- Domain admin account with computer join privileges

### Domain Join Process
1. VM is created from Packer template
2. VM gets static IP configuration
3. DNS points to domain controllers
4. VM automatically joins specified domain during customization
5. Computer account created in AD with name `${vm-name}-${count.index + 1}`

---

## WEBSPHERE ND DEPLOYMENT

### Required Variables (ansible-websphere/inventory/websphere_hosts)

| Variable | Description | Example |
|----------|-------------|---------|
| `was_version` | WebSphere version | `9.0.5.0` or `8.5.5.0` |
| `was_type` | WebSphere type | `ND` (Network Deployment) or `BASE` |
| `iim_repository_url` | Installation Manager URL | `http://192.168.1.200/installation` |
| `was_repository_url` | WebSphere binaries URL | `http://192.168.1.200/was/9.0.5` |
| `was_fixes_repository_url` | Fix packs URL | `http://192.168.1.200/was/9.0.5/FP015` |
| `was_username` | WebSphere admin user | `wsadmin` |
| `was_password` | WebSphere admin password | `WebSphereAdmin123` |
| `dmgr_hostname` | DMGR server hostname | `WebSphere-1` |

### WebSphere Version Configuration

**Supported Versions:**
- **WebSphere 9.0.5.0** (Recommended)
- **WebSphere 8.5.5.0** (Legacy)

**Supported Types:**
- **ND** (Network Deployment) - Multi-server enterprise setup
- **BASE** (Base/Express) - Single server setup

### WebSphere ND Output
- **DMGR Console**: `https://WebSphere-1:9043/ibm/console`
- **Username**: Value of `was_username`
- **Password**: Value of `was_password`
- **Cell Name**: `ConnectionsCell`
- **Profiles**: `Dmgr01` (DMGR), `AppSrv01` (App Servers)

### Deploy Command
```bash
# Complete pipeline
./deploy-websphere-nd.sh

# Or individual phases:
packer build -var-file="credentials.json" windows2019.json
cd terraform-windows-join-ad-domain && terraform apply
ansible-playbook -i ansible-websphere/inventory/websphere_hosts \
  ansible-websphere/ansible-ibm-websphere/playbooks/ibm-was-nd-complete.yml
```

---

## EXAMPLE WEBSPHERE ND CONFIGURATION

### Sample Terraform values.auto.tfvars (WebSphere Infrastructure)
```hcl
# WebSphere ND Infrastructure (1 DMGR + 2 App Servers)
vm-name          = "WebSphere"
vm-count         = 3
vm-cpu           = "4"
vm-ram           = "8192"
windows_template = "Win2019-Template-Base"

# Network Configuration
ipv4_addresses   = ["192.168.1.100", "192.168.1.101", "192.168.1.102"]
ipv4_netmasks    = [24, 24, 24]
vmgateway        = "192.168.1.1"
dns_server_list  = ["192.168.1.10", "192.168.1.11"]

# Domain Configuration
domain                = "company.local"
domain_admin_user     = "domainadmin"
domain_admin_password = "DomainPassword123"
local_adminpass       = "LocalAdmin123"
```

### Sample WebSphere Inventory (ansible-websphere/inventory/websphere_hosts)
```ini
[dmgr]
WebSphere-1 ansible_host=192.168.1.100

[was_servers]
WebSphere-2 ansible_host=192.168.1.101 servers="['server1']"
WebSphere-3 ansible_host=192.168.1.102 servers="['server2']"

[all:vars]
# WebSphere Version Configuration
was_version=9.0.5.0
was_type=ND

# Repository URLs
iim_repository_url=http://192.168.1.200/installation
was_repository_url=http://192.168.1.200/was/9.0.5
was_fixes_repository_url=http://192.168.1.200/was/9.0.5/FP015

# WebSphere Configuration
was_username=wsadmin
was_password=WebSphereAdmin123
dmgr_hostname=WebSphere-1
```

### Expected Results
- **VM Names**: `WebSphere-1` (DMGR), `WebSphere-2` (App Server 1), `WebSphere-3` (App Server 2)
- **Domain Membership**: All VMs joined to `company.local`
- **WebSphere ND**: Complete cluster ready for applications
- **Admin Console**: `https://WebSphere-1:9043/ibm/console`

---

## EXECUTION ORDER

1. **Packer**: Build Windows template
2. **Terraform**: Deploy WebSphere infrastructure (3 VMs)
3. **Ansible**: Install WebSphere ND cluster
4. **Verify**: Access DMGR console and deploy applications

## IMPORTANT NOTES

1. **AD Domain Must Exist**: This setup does NOT create Active Directory - it joins existing domain
2. **WebSphere Repository**: Setup HTTP server with WebSphere binaries before Ansible phase
3. **VM Specifications**: Minimum 4 CPU, 8GB RAM for WebSphere servers
4. **Version Flexibility**: Configure `was_version` and `was_type` variables for different WebSphere versions
5. **Network Connectivity**: Ensure VMs can reach domain controllers and WebSphere repository
6. **Template Dependency**: Terraform requires Packer template to exist first
