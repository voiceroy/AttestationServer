#!/bin/bash

mkdir -p /data/db

ln -sf /data/attestation.db /opt/attestation/attestation.db

echo "Starting Java Server..."
cd /opt/attestation
java -Xmx512m -jar attestation-server.jar &

sleep 5

echo "Starting Nginx..."
nginx -c /etc/nginx/nginx.conf -g "daemon off;"
