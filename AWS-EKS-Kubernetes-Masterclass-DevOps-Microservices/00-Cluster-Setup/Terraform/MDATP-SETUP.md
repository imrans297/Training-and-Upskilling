# MDATP (Microsoft Defender for Endpoint) Setup

## Prerequisites

Before deploying the cluster, you need to configure the MDATP onboarding files.

## Steps to Configure MDATP

### 1. Get Onboarding Files from Microsoft Defender Portal

1. Log in to Microsoft 365 Defender portal
2. Navigate to **Settings** > **Endpoints** > **Onboarding**
3. Select **Linux Server** as the operating system
4. Download the onboarding package (contains JSON and Python script)

### 2. Update user-data.sh

Edit the `user-data.sh` file and replace the placeholder content:

#### Replace the JSON content:
```bash
cat <<EOF > /tmp/mdatp_onboard.json
[Paste your actual onboarding JSON content here]
EOF
```

#### Replace the Python script content:
```bash
cat <<EOS > /tmp/MicrosoftDefenderATPOnboardingLinuxServer.py
[Paste your actual Python onboarding script here]
EOS
```

### 3. Alternative: Use S3 for Onboarding Files

For better security, store onboarding files in S3:

```bash
# Upload files to S3
aws s3 cp mdatp_onboard.json s3://your-bucket/mdatp/
aws s3 cp MicrosoftDefenderATPOnboardingLinuxServer.py s3://your-bucket/mdatp/

# Update user-data.sh to download from S3
aws s3 cp s3://your-bucket/mdatp/mdatp_onboard.json /tmp/
aws s3 cp s3://your-bucket/mdatp/MicrosoftDefenderATPOnboardingLinuxServer.py /tmp/
```

## Tagging Configuration

All EC2 instances and ASG resources will be automatically tagged with:

- **Name**: training-cluster-node
- **Owner**: imran.shaikh@einfochips.com
- **Project**: Internal POC
- **DM**: Shahid Raza
- **Department**: PES-Digital
- **Environment**: training
- **ENDDate**: 30-11-2025
- **ManagedBy**: Terraform
- **Purpose**: EKS Training Cluster

## Verification

After cluster deployment, verify MDATP installation:

```bash
# SSH to a node
ssh -i eks-demo-1_keyIMR.pem ec2-user@<node-private-ip>

# Check MDATP health
sudo mdatp health

# Check MDATP connectivity
sudo mdatp connectivity test
```

## Troubleshooting

If MDATP installation fails:

1. Check user data logs:
   ```bash
   sudo cat /var/log/cloud-init-output.log
   ```

2. Manually run installation:
   ```bash
   sudo bash /var/lib/cloud/instance/user-data.txt
   ```

3. Verify MDATP service:
   ```bash
   sudo systemctl status mdatp
   ```
