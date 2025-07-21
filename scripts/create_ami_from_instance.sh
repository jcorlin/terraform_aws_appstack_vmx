#!/bin/bash

set -e

usage() {
  echo "Usage: $0 -i <instance-id> -r <region> -n <name> [-m]"
  echo ""
  echo "Options:"
  echo "  -i, --instance-id   Source EC2 instance ID"
  echo "  -r, --region        AWS region"
  echo "  -n, --name          Name for the new AMI"
  echo "  -m, --monitor       Monitor AMI creation status (optional)"
  exit 1
}

# Defaults
MONITOR=false

# Parse args
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -i|--instance-id) INSTANCE_ID="$2"; shift ;;
    -r|--region) REGION="$2"; shift ;;
    -n|--name)   AMI_NAME="$2"; shift ;;
    -m|--monitor) MONITOR=true ;;
    -h|--help) usage ;;
    *) echo "Unknown parameter: $1" && usage ;;
  esac
  shift
done

# Validation
if [[ -z "$INSTANCE_ID" || -z "$REGION" || -z "$AMI_NAME" ]]; then
  echo "Error: Missing required arguments."
  usage
fi

echo "📦 Creating AMI from instance:"
echo "   Instance ID : $INSTANCE_ID"
echo "   Region      : $REGION"
echo "   AMI Name    : $AMI_NAME"

# Create the AMI
CREATE_OUTPUT=$(aws ec2 create-image \
  --instance-id "$INSTANCE_ID" \
  --name "$AMI_NAME" \
  --region "$REGION" \
  --no-reboot \
  --output json)

AMI_ID=$(echo "$CREATE_OUTPUT" | jq -r .ImageId)

echo "✅ AMI creation initiated. New AMI ID: $AMI_ID"

# Optional monitoring
if [ "$MONITOR" = true ]; then
  echo "🔍 Monitoring AMI creation status..."
  while true; do
    STATE=$(aws ec2 describe-images \
      --image-ids "$AMI_ID" \
      --region "$REGION" \
      --query "Images[0].State" \
      --output text)

    case "$STATE" in
      available)
        echo "🎉 AMI is now available: $AMI_ID"
        break
        ;;
      pending)
        echo "⏳ Still pending... checking again in 10 seconds"
        sleep 10
        ;;
      *)
        echo "❌ Unexpected AMI state: $STATE. Good luck with your investigation, Sherlock!"
        exit 1
        ;;
    esac
  done
else
  echo "📝 To monitor manually:"
  echo "    aws ec2 describe-images --image-ids $AMI_ID --region $REGION --query 'Images[0].State'"
fi
