#!/bin/bash

mkdir -p ~/.shh

touch ~/.ssh/authorized_keys

PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

if ! grep -qxF "$PUBLIC_KEY" ~/.ssh/authorized_keys; then
    echo "$PUBLIC_KEY" >> ~/.ssh/authorized_keys
fi