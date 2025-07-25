#!/bin/bash
# generate_le_cert.sh
# Usage: ./generate_le_cert.sh <domain> <email>
# Generates Let's Encrypt certs using certbot and exports them for offline transfer

set -e
DOMAIN="$1"
EMAIL="$2"
OUTPUT_DIR="le_certs_$DOMAIN"

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
  echo "Usage: $0 <domain> <email>"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Run certbot to generate certs (requires DNS-01 or HTTP-01 challenge)
certbot certonly --manual --preferred-challenges dns --email "$EMAIL" --agree-tos --no-eff-email -d "$DOMAIN" --manual-public-ip-logging-ok

# Copy cert and key to output dir
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem "$OUTPUT_DIR/cert.pem"
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem "$OUTPUT_DIR/key.pem"

# Instructions for user
cat <<EOF
Certificates generated!
Copy $OUTPUT_DIR/cert.pem and $OUTPUT_DIR/key.pem to your device using adb or USB.
Example:
  adb push $OUTPUT_DIR/cert.pem /data/rayhunter/ssl/cert.pem
  adb push $OUTPUT_DIR/key.pem /data/rayhunter/ssl/key.pem
Then run install_le_cert.py on the device to install and validate.
EOF
