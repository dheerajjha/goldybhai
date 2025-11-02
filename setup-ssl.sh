#!/bin/bash
# SSL Setup Script for GoldyBhai API
if [ -z "$1" ]; then
    echo "Usage: $0 <domain-name>"
    exit 1
fi
DOMAIN=$1
echo "Setting up SSL for domain: $DOMAIN"
sed -i "s/server_name _;/server_name $DOMAIN;/" /etc/nginx/sites-available/goldybhai
nginx -t && systemctl reload nginx
certbot --nginx -d $DOMAIN --non-interactive --agree-tos --redirect
echo "SSL setup complete! Your API is now at: https://$DOMAIN"
