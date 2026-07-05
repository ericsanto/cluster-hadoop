#!/bin/bash

mkdir -p ~/.shh

touch ~/.ssh/authorized_keys

PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

if ! grep -qxF "$PUBLIC_KEY" ~/.ssh/authorized_keys; then
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
fi

if [[ "$HOSTNAME" == "master" ]] && ! grep -q "^Host MacBookPro$" ~/.ssh/config 2>/dev/null; then
    cat >> ~/.ssh/config <<EOF
Host MacBookPro
    HostName 10.144.161.17
    User hadoop
    Port 2222
EOF
fi