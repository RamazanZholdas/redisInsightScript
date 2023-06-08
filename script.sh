#!/bin/bash
output=$(aws secretsmanager get-secret-value --region us-east-1 --secret-id redisProdEndpoints --query SecretString --output text | jq -r .endpoints)
IFS=',' read -ra endpoints <<< "$output"

for endpoint in "${endpoints[@]}"; do
    payload=$(cat <<EOF
{
    "name": "$endpoint",
    "connectionType": "STANDALONE",
    "host": "$endpoint",
    "port": 6379
}
EOF
)

    response=$(curl -X POST \
        http://localhost:8001/api/instance/ \
        -H 'Content-Type: application/json' \
        -d "$payload")

done
