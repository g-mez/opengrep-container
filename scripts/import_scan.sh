#!/bin/bash
# Description: Used to import opengrep json reports into Defect Dojo
# import_scan.sh
# Usage:
#   export DEFECT_DOJO_API_TOKEN="your_token_here"
#   ./import_scan.sh --host https://host:8080 --product-name "My Product" --engagement-name "My Engagement" --report scan.json

# Default values
SCAN_TYPE="Semgrep JSON Report"
ACTIVE="true"
VERIFIED="true"

# -------------------------------
# Parse arguments
# -------------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    --host)
      HOST="$2"
      shift 2
      ;;
    --product-name)
      PRODUCT_NAME="$2"
      shift 2
      ;;
    --engagement-name)
      ENGAGEMENT_NAME="$2"
      shift 2
      ;;
    --report)
      REPORT_FILE="$2"
      shift 2
      ;;
    --scan-type)
      SCAN_TYPE="$2"
      shift 2
      ;;
    --active)
      ACTIVE="$2"
      shift 2
      ;;
    --verified)
      VERIFIED="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# -------------------------------
# Validate required arguments
# -------------------------------
if [[ -z "$HOST" || -z "$PRODUCT_NAME" || -z "$ENGAGEMENT_NAME" || -z "$REPORT_FILE" ]]; then
  echo "Usage: $0 --host <host_url> --product-name <product_name> --engagement-name <name> --report <file.json> [--scan-type <type>] [--active true|false] [--verified true|false]"
  exit 1
fi

if [[ -z "$DEFECT_DOJO_API_TOKEN" ]]; then
  echo "Error: DEFECT_DOJO_API_TOKEN environment variable is not set."
  exit 1
fi

if [[ ! -f "$REPORT_FILE" ]]; then
  echo "Error: Report file '$REPORT_FILE' does not exist."
  exit 1
fi

# -------------------------------
# Get product ID by product name
# -------------------------------
PRODUCT_ID=$(curl -s -k -G "$HOST/api/v2/products/" \
  -H "Authorization: Token $DEFECT_DOJO_API_TOKEN" \
  --data-urlencode "name=$PRODUCT_NAME" \
  | jq -r '.results[0].id')

if [[ "$PRODUCT_ID" == "null" || -z "$PRODUCT_ID" ]]; then
  echo "Error: Product '$PRODUCT_NAME' not found in DefectDojo."
  exit 1
fi

# -------------------------------
# Lookup engagement by name
# -------------------------------
ENGAGEMENT_ID=$(curl -s -k -G "$HOST/api/v2/engagements/" \
  -H "Authorization: Token $DEFECT_DOJO_API_TOKEN" \
  --data-urlencode "name=$ENGAGEMENT_NAME" \
  | jq -r '.results[0].id')

# -------------------------------
# If not found, create engagement
# -------------------------------
if [[ "$ENGAGEMENT_ID" == "null" || -z "$ENGAGEMENT_ID" ]]; then
  echo "Engagement '$ENGAGEMENT_NAME' not found. Creating..."
  ENGAGEMENT_ID=$(curl -s -k -X POST "$HOST/api/v2/engagements/" \
    -H "Authorization: Token $DEFECT_DOJO_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$ENGAGEMENT_NAME\",
      \"product\": $PRODUCT_ID,
      \"status\": \"In Progress\",
      \"target_start\": \"$(date +%Y-%m-%d)\",
      \"target_end\": \"$(date -d '+30 days' +%Y-%m-%d)\"
    }" | jq -r '.id')
  echo "Created engagement with ID: $ENGAGEMENT_ID"
fi

# -------------------------------
# Upload scan
# -------------------------------
response=$(curl -s -w "\n%{http_code}" -k -X POST "$HOST/api/v2/import-scan/" \
    -H "Authorization: Token $DEFECT_DOJO_API_TOKEN" \
    -F "engagement=$ENGAGEMENT_ID" \
    -F "scan_type=$SCAN_TYPE" \
    -F "file=@$REPORT_FILE" \
    -F "active=$ACTIVE" \
    -F "verified=$VERIFIED")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [[ "$http_code" =~ 2[0-9]{2} ]]; then
    echo "Scan imported successfully!"
    echo "$body"
else
    echo "Failed to import scan. HTTP code: $http_code"
    echo "$body"
    exit 1
fi
