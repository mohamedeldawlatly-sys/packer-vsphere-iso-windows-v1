#!/bin/bash
set -e

echo "=========================================="
echo "WebSphere ND Complete Deployment Workflow"
echo "=========================================="

# Configuration
TERRAFORM_DIR="terraform-windows-join-ad-domain"
ANSIBLE_DIR="ansible-websphere"
WEBSPHERE_REPO="https://github.com/ebasso/ansible-ibm-websphere.git"

# Phase 1: Build Windows Template
echo ""
echo "Phase 1: Building Windows 2019 Template with Packer..."
echo "------------------------------------------------------"
if [ ! -f "credentials.json" ]; then
    echo "ERROR: credentials.json not found!"
    echo "Please create credentials.json with vSphere connection details"
    exit 1
fi

packer build -var-file="credentials.json" windows2019.json
echo "✓ Windows 2019 template created successfully"

# Phase 2: Deploy Infrastructure with Terraform
echo ""
echo "Phase 2: Deploying WebSphere Infrastructure with Terraform..."
echo "------------------------------------------------------------"
cd $TERRAFORM_DIR

if [ ! -f "values.auto.tfvars" ]; then
    echo "ERROR: values.auto.tfvars not found in $TERRAFORM_DIR!"
    echo "Please configure Terraform variables for WebSphere deployment"
    exit 1
fi

terraform init
terraform plan
terraform apply -auto-approve

# Get VM IP addresses
echo "Getting deployed VM IP addresses..."
terraform output -json > ../vm_outputs.json
cd ..

echo "✓ WebSphere infrastructure deployed successfully"

# Phase 3: Wait for VMs to be ready
echo ""
echo "Phase 3: Waiting for VMs to be ready..."
echo "---------------------------------------"
echo "Waiting 5 minutes for VMs to complete domain join and be accessible..."
sleep 300

# Phase 4: Setup Ansible WebSphere Repository
echo ""
echo "Phase 4: Setting up WebSphere Ansible Repository..."
echo "---------------------------------------------------"
if [ ! -d "$ANSIBLE_DIR/ansible-ibm-websphere" ]; then
    mkdir -p $ANSIBLE_DIR
    cd $ANSIBLE_DIR
    git clone $WEBSPHERE_REPO
    cd ..
    echo "✓ WebSphere Ansible repository cloned"
else
    echo "✓ WebSphere Ansible repository already exists"
fi

# Phase 5: Install WebSphere ND
echo ""
echo "Phase 5: Installing WebSphere ND with Ansible..."
echo "------------------------------------------------"
echo "NOTE: Ensure your HTTP server is running with WebSphere installation files"
echo "Repository structure should be:"
echo "  /var/www/html/installation/ - IBM Installation Manager"
echo "  /var/www/html/was/8.5.5/    - WebSphere ND binaries"
echo "  /var/www/html/was/8.5.5/FP15/ - WebSphere Fix Packs"
echo ""

read -p "Is your WebSphere repository HTTP server ready? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please setup your WebSphere repository HTTP server first"
    echo "Update the repository URLs in ansible-websphere/inventory/websphere_hosts"
    exit 1
fi

# Run WebSphere ND installation
ansible-playbook -i $ANSIBLE_DIR/inventory/websphere_hosts \
  $ANSIBLE_DIR/ansible-ibm-websphere/playbooks/ibm-was-nd-complete.yml

echo ""
echo "=========================================="
echo "WebSphere ND Deployment Complete!"
echo "=========================================="
echo ""
echo "Access Information:"
echo "-------------------"
echo "DMGR Admin Console: https://WebSphere-1:9043/ibm/console"
echo "Username: wsadmin"
echo "Password: WebSphereAdmin123"
echo ""
echo "Servers Deployed:"
echo "- WebSphere-1 (Deployment Manager)"
echo "- WebSphere-2 (Application Server 1)"  
echo "- WebSphere-3 (Application Server 2)"
echo ""
echo "Next Steps:"
echo "1. Access the DMGR console to verify installation"
echo "2. Create application clusters"
echo "3. Deploy your applications"
echo "4. Configure load balancing (if HTTP server installed)"
echo ""
