#!/bin/bash

# --------- CONFIGURATION ----------
REGION="ap-south-1"
BUCKET_NAME="arijit-devops-$(date +%s)"
INSTANCE_NAME="DevOps-Test-Instance"
AMI_ID="ami-03bb6d83c60fc5f7c"  # Amazon Linux 2023 (Mumbai)
INSTANCE_TYPE="t2.micro"
KEY_NAME="your-key-name"       # Replace with your actual key name
SECURITY_GROUP_ID="sg-xxxxxx"  # Replace with your SG ID
SUBNET_ID="subnet-xxxxxx"      # Replace with your Subnet ID
IAM_USER="arijit-cli-user"
LOG_FILE="aws-automation-$(date +%Y%m%d_%H%M%S).log"

# --------- FUNCTIONS ----------

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

create_s3_bucket() {
    log "✅ Creating S3 bucket: $BUCKET_NAME..."
    aws s3 mb s3://$BUCKET_NAME --region $REGION
}

launch_ec2_instance() {
    log "✅ Launching EC2 instance..."
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type $INSTANCE_TYPE \
        --key-name $KEY_NAME \
        --security-group-ids $SECURITY_GROUP_ID \
        --subnet-id $SUBNET_ID \
        --region $REGION \
        --count 1 \
        --query "Instances[0].InstanceId" \
        --output text)

    log "🆔 EC2 Instance launched: $INSTANCE_ID"

    # Tag the instance
    aws ec2 create-tags \
        --resources $INSTANCE_ID \
        --tags Key=Name,Value=$INSTANCE_NAME \
        --region $REGION
    log "🏷️ Tagged instance with Name=$INSTANCE_NAME"
}

create_iam_user() {
    log "✅ Creating IAM user: $IAM_USER..."
    aws iam create-user --user-name $IAM_USER
    log "🔑 Creating access key..."
    aws iam create-access-key --user-name $IAM_USER >> "$LOG_FILE"
    log "📎 Attaching AdministratorAccess policy..."
    aws iam attach-user-policy --user-name $IAM_USER \
        --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
}

# --------- MAIN ----------
log "🚀 Starting AWS automation script..."

create_s3_bucket
launch_ec2_instance
create_iam_user

log "✅ All done!"
