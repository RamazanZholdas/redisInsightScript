#!/bin/bash
output=$(aws secretsmanager get-secret-value --region us-east-1 --secret-id redisProdEndpoints --query SecretString --output text | jq -r .endpoints)
names=$(aws secretsmanager get-secret-value --region us-east-1 --secret-id redisProdEndpoints --query SecretString --output text | jq -r .names)
passwords=$(aws secretsmanager get-secret-value --region us-east-1 --secret-id redisProdEndpoints --query SecretString --output text | jq -r .token)
redisInsightPassword=$(aws secretsmanager get-secret-value --region us-east-1 --secret-id ramazansRedisInsightPassword --query SecretString --output text | jq -r .redisInsightPassword)

IFS=',' read -ra endpoints <<< "$output"
IFS=',' read -ra namesArr <<< "$names"
IFS=',' read -ra passwordsArr <<< "$passwords"

for index in "${!endpoints[@]}"; do
    endpoint="${endpoints[index]}"
    name="${namesArr[index]:-}"
    password="${passwordsArr[index]:-}"

    if [ -z "$name" ]; then
        name="$endpoint"
    fi

    if [ -z "$password" ]; then
        password=""

        if [ "$index" -eq "0" ]; then
            password="$redisInsightPassword"
        fi
    fi

    # Remove trailing comma if it exists in the last character of name, password, and endpoint
    name="${name%,}"
    password="${password%,}"
    endpoint="${endpoint%,}"

    payload=$(cat <<EOF
{
    "name": "$name",
    "connectionType": "STANDALONE",
    "password": "$password",
    "host": "$endpoint",
    "port": 6379,
    "tls": {
        "useTls": true,
        "clientAuth": false,
        "verifyServerCert": false
    }
}
EOF
)

    response=$(curl -X POST \
        https://redis.training.edetekapps.com/prod/api/instance/ \
        -H 'Content-Type: application/json' \
        -H "password: $redisInsightPassword" \
        -d "$payload")

done
