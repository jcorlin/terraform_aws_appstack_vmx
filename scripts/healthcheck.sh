#!/bin/bash

CONFIG_FILE="./healthcheck.conf"
DEFAULT_DNS="system"
ALT_DNS=("8.8.8.8" "208.67.222.222")

AWS_ALB_SUFFIX=".elb.amazonaws.com"

function status_ok() { echo -e "\e[32m[OK]\e[0m $1"; }
function status_fail() { echo -e "\e[31m[FAIL]\e[0m $1"; }
function status_info() { echo -e "\e[34m[INFO]\e[0m $1"; }

# Track pass/fail
PASS_DNS=0
PASS_ALB=0
PASS_HTTP=0
PASS_VERSION=0

# Load config
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing config file: $CONFIG_FILE"
  exit 1
fi

source "$CONFIG_FILE"

if [[ -z "$APP_CNAME" || -z "$TEST_PATH" ]]; then
  echo "APP_CNAME and TEST_PATH must be set in $CONFIG_FILE"
  exit 1
fi

EXPECTED_STATUS_MIN="${EXPECTED_STATUS_MIN:-200}"
EXPECTED_STATUS_MAX="${EXPECTED_STATUS_MAX:-399}"

echo "===== Healthcheck for $APP_CNAME$TEST_PATH ====="
echo "Expecting status code between $EXPECTED_STATUS_MIN and $EXPECTED_STATUS_MAX"
echo

# DNS Resolution
echo "🧠 DNS Resolution Tests"

PASS_DNS_TMP=0
resolve_and_display() {
  local resolver="$1"
  local result

  if [[ "$resolver" == "system" ]]; then
    result=$(dig +short "$APP_CNAME")
  else
    result=$(dig @"$resolver" +short "$APP_CNAME")
  fi

  if [[ -n "$result" ]]; then
    status_ok "DNS resolution via $resolver: $result"
    PASS_DNS_TMP=1
  else
    status_fail "DNS resolution via $resolver failed"
  fi
}

resolve_and_display "$DEFAULT_DNS"
for dns in "${ALT_DNS[@]}"; do
  resolve_and_display "$dns"
done
[[ $PASS_DNS_TMP -eq 1 ]] && PASS_DNS=1
echo

# DNS Chain & ALB Check
echo "🔗 DNS Chain and ALB Verification"
DNS_CHAIN=$(dig +short CNAME "$APP_CNAME")

if [[ -z "$DNS_CHAIN" ]]; then
  status_info "No CNAME found — this may be an A record"
  ALB_CHECK=$(dig +short "$APP_CNAME" | head -n1)
else
  # DNS_CHAIN_CLEAN="${DNS_CHAIN%%.}"
  DNS_CHAIN_CLEAN=$(echo "$DNS_CHAIN" | sed -E 's/\.$//' | xargs)
  echo "CNAME: $DNS_CHAIN_CLEAN"
  if [[ "$DNS_CHAIN_CLEAN" == *"$AWS_ALB_SUFFIX" ]]; then
    status_ok "CNAME target appears to be an AWS ALB ($DNS_CHAIN_CLEAN)"
    PASS_ALB=1
  else
    status_fail "CNAME target '$DNS_CHAIN_CLEAN' does not match expected AWS ALB pattern '*$AWS_ALB_SUFFIX'"
    status_info "Note: There may be multiple chained CNAMEs — this only shows the first resolved link"
  fi
  ALB_CHECK="$DNS_CHAIN_CLEAN"
fi

IP=$(dig +short "$ALB_CHECK" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)
if [[ -n "$IP" ]]; then
  status_info "Resolved IP: $IP"
else
  status_fail "Could not resolve ALB or A record IP"
fi
echo

# HTTP Test & Version Detection
echo "🌐 HTTP Test for https://$APP_CNAME$TEST_PATH"
HTTP_RESPONSE=$(curl -sk -w "\n%{http_code}" "https://$APP_CNAME$TEST_PATH")
HTTP_BODY=$(echo "$HTTP_RESPONSE" | head -n -1)
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n1)

if [[ "$HTTP_STATUS" =~ ^[0-9]+$ && "$HTTP_STATUS" -ge "$EXPECTED_STATUS_MIN" && "$HTTP_STATUS" -le "$EXPECTED_STATUS_MAX" ]]; then
  status_ok "HTTP $HTTP_STATUS received"
  PASS_HTTP=1
else
  status_fail "Unexpected HTTP status: $HTTP_STATUS"
fi

echo
echo "🧾 Response Snippet:"
echo "--------------------"
echo "$HTTP_BODY" \
  | sed -E 's/<[^>]+>//g' \
  | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//' \
  | grep -v '^$' \
  | head -n 15
echo "--------------------"

# Version check (HTML stripped)
HTTP_BODY_STRIPPED=$(echo "$HTTP_BODY" | sed -E 's/<[^>]+>//g')
VERSION=$(echo "$HTTP_BODY_STRIPPED" | grep -Eo 'View release notes for Django [0-9]+\.[0-9]+' | head -n1 | grep -Eo '[0-9]+\.[0-9]+')

if [[ -n "$VERSION" ]]; then
  status_info "App Version: $VERSION"
  PASS_VERSION=1
else
  VERSION_META=$(echo "$HTTP_BODY" | grep -i '<meta name="version"' | sed -E 's/.*content="([^"]+)".*/\1/')
  if [[ -n "$VERSION_META" ]]; then
    status_info "App Version (meta): $VERSION_META"
    PASS_VERSION=1
  else
    status_info "App version not found in response"
  fi
fi

# Final Summary
echo
echo "===================="
echo "✅ Healthcheck Summary"
echo "===================="
[[ $PASS_DNS -eq 1 ]]      && echo "✔ DNS resolution passed"     || echo "✖ DNS resolution failed"
[[ $PASS_ALB -eq 1 ]]      && echo "✔ ALB CNAME verification passed" || echo "✖ ALB CNAME verification failed"
[[ $PASS_HTTP -eq 1 ]]     && echo "✔ HTTP response check passed" || echo "✖ HTTP response check failed"
[[ $PASS_VERSION -eq 1 ]]  && echo "✔ Version string found"       || echo "✖ Version string not found"

echo
if [[ $PASS_DNS -eq 1 && $PASS_ALB -eq 1 && $PASS_HTTP -eq 1 ]]; then
  echo -e "🎉 \e[32mOVERALL STATUS: PASS\e[0m"
  exit 0
else
  echo -e "❌ \e[31mOVERALL STATUS: FAIL\e[0m"
  exit 1
fi
