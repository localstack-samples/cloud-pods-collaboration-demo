#!/bin/bash
api_id=$(cd terraform; tflocal output --raw rest_api_id)
echo ${api_id}
curl --location "http://${api_id}.execute-api.localhost.localstack.cloud:4566/dev/productApi" \
--header 'Content-Type: application/json' \
--data '{
  "id": "34534",
  "name": "EcoFriendly Water Bottle",
  "description": "A durable, eco-friendly water bottle designed to keep your drinks cold for up to 24 hours and hot for up to 12 hours. Made from high-quality, food-grade stainless steel, it'\''s perfect for your daily hydration needs.",
  "price": "29.99"
}'

curl --location "http://${api_id}.execute-api.localhost.localstack.cloud:4566/dev/productApi?id=34534"
