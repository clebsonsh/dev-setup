#!/bin/bash

ok() { echo -e '\e[32m'$1'\e[m'; }         # Green
working() { echo -ne '\e[1;33m'$1'\e[m'; } # Yellow

NGINX_AVAILABLE_VHOSTS='/etc/nginx/sites-available'
NGINX_ENABLED_VHOSTS='/etc/nginx/sites-enabled'
PROJECT_DIR=$PWD
PROJECT_NAME=$(basename $PROJECT_DIR)

working "Creating nginx config file for this site... "
rm $NGINX_AVAILABLE_VHOSTS/$PROJECT_NAME.conf
cat >$NGINX_AVAILABLE_VHOSTS/$PROJECT_NAME.conf <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $PROJECT_NAME.test;

    root $PROJECT_DIR/public;

    access_log $PROJECT_DIR/storage/logs/access.log;
    error_log $PROJECT_DIR/storage/logs/error.log;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_hide_header X-Powered-By;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

ok "Done."

working "Enabling site... "

rm $NGINX_ENABLED_VHOSTS/$PROJECT_NAME.conf
ln -s $NGINX_AVAILABLE_VHOSTS/$PROJECT_NAME.conf $NGINX_ENABLED_VHOSTS/

ok "Done."

working "Restarting NGINX"

systemctl restart nginx

ok "Done."

working "Adding site to /etc/hosts"

if ! grep -q $PROJECT_NAME /etc/hosts; then
  echo "127.0.0.1 $PROJECT_NAME.test" >>/etc/hosts
fi

ok "Done. Site fully added"
