#!/bin/bash
# Reproduce the scenario from the collaborative debugging tutorial, then fix it:
# 1. adding products works
# 2. reading a product fails, because the policy misses dynamodb:GetItem and
#    LocalStack enforces IAM, and the get-product logs name the denied action
# 3. adding dynamodb:GetItem to the policy makes the read succeed
# The original policy version is restored on exit, so the stack matches main.tf.
set -euo pipefail

TF_DIR=${TF_DIR:-terraform}
ENDPOINT=${ENDPOINT:-http://localhost:4566}
POLICY_ARN=arn:aws:iam::000000000000:policy/LambdaDynamoDBAccess
MAX_ATTEMPTS=${MAX_ATTEMPTS:-30}

iam_state=$(curl -s "$ENDPOINT/_aws/iam/config" | jq -r .state)
if [ "$iam_state" != "ENFORCED" ]; then
  echo "Test failed: IAM is not enforced (state $iam_state). Start LocalStack with LOCALSTACK_ENFORCE_IAM=1."
  exit 1
fi

REST_API_ID=$(cd "$TF_DIR" && lstk tf output -raw rest_api_id)
URL="http://$REST_API_ID.execute-api.localhost.localstack.cloud:4566/dev/productApi"
echo "API: $URL"

START_MS=$(( $(date +%s) * 1000 ))

for product in '{"id": "34534", "name": "EcoFriendly Water Bottle", "description": "A durable, eco-friendly water bottle.", "price": "29.99"}' \
               '{"id": "82736", "name": "Sustainable Hydration Flask", "description": "A sustainable hydration flask.", "price": "31.50"}'; do
  response=$(curl -s -m 120 -H 'Content-Type: application/json' -d "$product" "$URL")
  if [ "$response" != "Product added/updated successfully." ]; then
    echo "Test failed: adding $product returned '$response'"
    exit 1
  fi
done
echo "PASS: added two products"

response=$(curl -s -m 120 -w '\n%{http_code}' "$URL?id=34534")
status=${response##*$'\n'}
if [ "$status" != "500" ]; then
  echo "Test failed: GET returned HTTP $status before the fix, expected the 500 from the missing permission"
  exit 1
fi
echo "PASS: reading a product fails with HTTP 500"

logged=""
for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  logged=$(lstk aws logs filter-log-events --log-group-name /aws/lambda/get-product \
    --start-time "$START_MS" --query 'events[].message' --output text 2>/dev/null || true)
  [[ "$logged" == *"not authorized to perform: dynamodb:GetItem"* ]] && break
  sleep 2
done
if [[ "$logged" != *"not authorized to perform: dynamodb:GetItem"* ]]; then
  echo "Test failed: get-product did not log the denied dynamodb:GetItem call"
  exit 1
fi
echo "PASS: get-product logs show the denied dynamodb:GetItem call"

ORIGINAL_VERSION=$(lstk aws iam get-policy --policy-arn "$POLICY_ARN" --query Policy.DefaultVersionId --output text)
FIXED_VERSION=""
restore_policy() {
  if [ -n "$FIXED_VERSION" ]; then
    lstk aws iam set-default-policy-version --policy-arn "$POLICY_ARN" --version-id "$ORIGINAL_VERSION"
    lstk aws iam delete-policy-version --policy-arn "$POLICY_ARN" --version-id "$FIXED_VERSION"
  fi
}
trap restore_policy EXIT

FIXED_VERSION=$(lstk aws iam create-policy-version --policy-arn "$POLICY_ARN" --set-as-default \
  --query PolicyVersion.VersionId --output text --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["dynamodb:GetItem", "dynamodb:Scan", "dynamodb:Query", "dynamodb:UpdateItem", "dynamodb:PutItem"],
      "Resource": "*"
    }]
  }')
echo "Added dynamodb:GetItem to the policy (version $FIXED_VERSION)"

response=$(curl -s -m 120 "$URL?id=34534")
if ! echo "$response" | jq -e '.id == "34534" and .name == "EcoFriendly Water Bottle"' > /dev/null 2>&1; then
  echo "Test failed: GET returned '$response' after the fix"
  exit 1
fi
echo "PASS: reading a product works once the policy allows dynamodb:GetItem"

echo "Test passed: the tutorial's IAM bug reproduces and the fix resolves it"
