#!/bin/bash

# Functions
ok() { echo -e '\e[32m'$1'\e[m'; }         # Green
working() { echo -ne '\e[1;33m'$1'\e[m'; } # Yellow

# Variables
NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
PROJECT_DIR=$PWD
PROJECT_NAME=$(basename $PROJECT_DIR)

working "Removing nginx config file for this site... "

rm -f $NGINX_AVAILABLE_VHOSTS/$PROJECT_NAME.conf

ok "Done."

working "Removing symbolic link..."

rm -f $NGINX_ENABLED_VHOSTS/$PROJECT_NAME.conf

ok "Done."

working "Restarting NGINX... "

systemctl restart nginx

ok "Done."

working "Removing site from /etc/hosts... "

sed -i /$PROJECT_NAME.test/d /etc/hosts

ok "Done. Site fully removed!"
