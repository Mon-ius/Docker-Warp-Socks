#!/bin/dash

get_end_point() {
    _ACCOUNT_ID="$1"
    _END_POINT="https://api.cloudflareclient.com/v0a2024/reg"

    if [ -z "$_ACCOUNT_ID" ]; then
        echo "$_END_POINT"
    else
        echo "$_END_POINT/$_ACCOUNT_ID"
    fi
}

get_tos() {
    date --utc +"%Y-%m-%dT%H:%M:%S.%3NZ" | awk '{print substr($0, 1, length($0)-1)"-02:00"}'
}

get_key() {
    openssl genpkey -algorithm X25519
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

get_account() {
    _LICENSE=$1
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

    if [ -z "$_LICENSE" ]; then
        echo "Response from free: $RESPONSE"
    else
        account=$(echo "$RESPONSE" | grep -o '"id": *"[^"]*"' | head -n 1 | sed 's/"id": *"\([^"]*\)"/\1/')
        token=$(echo "$RESPONSE" | grep -o '"token": *"[^"]*"' | sed 's/"token": *"\([^"]*\)"/\1/')
        _=$(update_account "$account" "$token" "$_LICENSE")
        response=$(check_account "$account" "$token")
        echo "Response from plus: $response"
    fi

    echo "\"private_key\":\"$private_key\""
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

test() {
    _ARCH="linux/amd64" # Expected `linux/amd64``, `linux/arm64`, `linux/arm`, and `linux/s390x`;
    _NAME="warp_socks"
    _KEY=""
    _SOCK_USER=""
    _SOCK_PWD=""
    _PORT="9091"
    _VER="v2"

    KEY="${7:-$_KEY}"
    SOCK_PWD="${6:-$SOCK_PWD}"
    SOCK_USER="${5:-$SOCK_USER}"
    PORT="${4:-$_PORT}"
    VER="${3:-$VER}"
    ARCH="${2:-$_ARCH}"
    NAME="${1:-$_NAME}"

    sudo docker run --privileged --platform="${ARCH}" --restart=always -itd \
        --name "${NAME}" -e LOG=1 \
        -e WGCF_LICENSE_KEY="${KEY}" \
        -e SOCK_USER="${SOCK_USER}" \
        -e SOCK_PWD="${SOCK_PWD}" \
        --sysctl net.ipv6.conf.all.disable_ipv6=0 \
        --sysctl net.ipv4.conf.all.src_valid_mark=1 \
        --cap-add NET_ADMIN --cap-add SYS_MODULE \
        -p "${PORT}":"9091" \
        -v /lib/modules:/lib/modules \
        "monius/docker-warp-socks:${VER}"
}

if [ $# -le 1 ]; then
    info=$(get_account "$1")
    echo "$info"
else
    test "$@"
fi