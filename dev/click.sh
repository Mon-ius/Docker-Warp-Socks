#!/bin/dash

get_end_point() {
    _ACCOUNT_ID="$1"
    _END_POINT="https://api.cloudflareclient.com/v0a2024/reg"

    if [ -z "$_ACCOUNT_ID" ]; then
        echo "$_END_POINT"
    else
        echo "$_END_POINT/$_ACCOUNT_ID/account"
    fi
}

get_tos() {
    date --utc +"%Y-%m-%dT%H:%M:%S.%3NZ" | awk '{print substr($0, 1, length($0)-1)"-02:00"}'
}

get_key() {
    openssl genpkey -algorithm X25519
}

get_account() {
    END_POINT=$(get_end_point)
    TOS=$(get_tos)
    KEY=$(get_key)

    private_key=$(echo "$KEY" | openssl pkey -outform DER | tail -c 32 | base64)
    public_key=$(echo "$KEY" | openssl pkey -pubout -outform DER | tail -c 32 | base64)

    JSON_PAYLOAD=$(cat <<EOF
    {
        "tos": "$TOS",
        "key": "$public_key"
    }
EOF
    )

    RESPONSE=$(curl -s -X POST "$END_POINT" \
        -H "Content-Type: application/json" \
        -H 'authority: cloudflareclient.com' \
        -H 'host: api.cloudflareclient.com' \
        -H 'accept-language: en-US,en;q=0.9' \
        -H 'connection: Keep-Alive' \
        -H 'origin: https://cloudflareclient.com' \
        -H 'referer: https://warp.plus' \
        -H 'user-agent: okhttp/4.12.1' \
        -d "$JSON_PAYLOAD")

    if [ -z "$RESPONSE" ]; then
        echo "Error: No response from server."
        return 1
    fi

    echo "Response from server: $RESPONSE"
    echo "\"private_key\":\"$private_key\""
}

update_account() {
    ACCOUNT=$1
    TOKEN=$2
    LICENSE=$3
    END_POINT=$(get_end_point "$ACCOUNT")

    JSON_PAYLOAD=$(cat <<EOF
    {
        "license": "$LICENSE"
    }
EOF
    )

    RESPONSE=$(curl -s -X PUT "$END_POINT" \
        -H "Content-Type: application/json" \
        -H 'authority: cloudflareclient.com' \
        -H 'host: api.cloudflareclient.com' \
        -H 'accept-language: en-US,en;q=0.9' \
        -H 'connection: Keep-Alive' \
        -H 'origin: https://cloudflareclient.com' \
        -H 'referer: https://warp.plus' \
        -H 'user-agent: okhttp/4.12.1' \
        -H "Authorization: Bearer $TOKEN" \
        -d "$JSON_PAYLOAD")

    if [ -z "$RESPONSE" ]; then
        echo "Error: No response from server."
        return 1
    fi

    echo "Update Response from server: $RESPONSE"
}

check_account() {
    ACCOUNT=$1
    TOKEN=$2
    END_POINT=$(get_end_point "$ACCOUNT")

    RESPONSE=$(curl -s "$END_POINT" \
        -H "Content-Type: application/json" \
        -H 'authority: cloudflareclient.com' \
        -H 'host: api.cloudflareclient.com' \
        -H 'accept-language: en-US,en;q=0.9' \
        -H 'connection: Keep-Alive' \
        -H 'origin: https://cloudflareclient.com' \
        -H 'referer: https://warp.plus' \
        -H 'user-agent: okhttp/4.12.1' \
        -H "Authorization: Bearer $TOKEN")

    if [ -z "$RESPONSE" ]; then
        echo "Error: No response from server."
        return 1
    fi

    echo "Check Response from server: $RESPONSE"
}

delete_account() {
    ACCOUNT=$1
    TOKEN=$2
    END_POINT=$(get_end_point "$ACCOUNT")

    RESPONSE=$(curl -s -X DELETE "$END_POINT" \
        -H "Content-Type: application/json" \
        -H 'authority: cloudflareclient.com' \
        -H 'host: api.cloudflareclient.com' \
        -H 'accept-language: en-US,en;q=0.9' \
        -H 'connection: Keep-Alive' \
        -H 'origin: https://cloudflareclient.com' \
        -H 'referer: https://warp.plus' \
        -H 'user-agent: okhttp/4.12.1' \
        -H "Authorization: Bearer $TOKEN")

    echo "Delete Response from server: $RESPONSE"
}

info=$(get_account)
echo "$info"