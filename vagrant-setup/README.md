# Vagrant Windows Domain + WebSphere Setup

## Prerequisites

1. **VirtualBox** installed
2. **Vagrant** installed
3. **Ansible** installed (for WebSphere deployment)
4. **WebSphere installer** uploaded to OneDrive (accessible URL)

## Setup Steps

### 1. Configure WebSphere Installer URL
Edit `ansible/websphere.yml` and set your OneDrive URL:
```yaml
vars:
  websphere_installer_url: "https://onedrive.live.com/download?cid=YOUR_ID&resid=YOUR_RESID"
```

### 2. Start Environment
```bash
cd vagrant-setup
vagrant up dc01          # Start domain controller first
vagrant up websphere01   # Start WebSphere server
```

### 3. Verify Setup
- **Domain Controller**: `vagrant ssh dc01`
- **WebSphere Server**: Access via RDP at `192.168.56.20`
- **WebSphere Console**: `http://192.168.56.20:9060/ibm/console`

## Network Configuration

| Server | IP | Role |
|--------|----|----- |
| dc01 | 192.168.56.10 | Domain Controller |
| websphere01 | 192.168.56.20 | WebSphere Server |

## Domain Details
- **Domain**: company.local
- **Admin User**: Administrator
- **Password**: vagrant

## Manual WebSphere Installation (Alternative)

If Ansible fails, manually:
1. RDP to websphere01
2. Download installer from OneDrive
3. Run silent installation:
```cmd
websphere_installer.exe -silent -acceptLicense -installLocation "C:\IBM\WebSphere\AppServer"
```

## Cleanup
```bash
vagrant destroy -f
```
