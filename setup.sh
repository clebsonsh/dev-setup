#!/bin/bash
set -e

USER=$(whoami)

echo "
        This script automates the installation of the essential components required for Full-Stack Laravel development:

          - PHP 8.3
          - Node 20
          - Composer
          - Nginx
          - MariaDB (user: root with no password)
          - Laravel Installer
          - NVM (Node Version Manager)
          - Yarn
"

if ! grep -q "^deb .*universe" /etc/apt/sources.list; then
  echo "
        Adding 'universe' repository...
  "
  sudo add-apt-repository universe -y
fi

echo "
        Updating system packages...
"
sudo apt update
sudo apt upgrade -y

echo "
        Installing basic tools...
"
mkdir ~/.local
mkdir ~/.local/bin
wget -q -O - https://raw.githubusercontent.com/clebsonsh/dev-setup/main/add-site >> ~/.local/bin/add-site
chmod +x ~/.local/bin/add-site

mkdir ~/.dev
mkdir ~/.dev/sites-available
mkdir ~/.dev/sites-enabled


sudo apt install htop curl git vim unzip -y
curl -s https://ohmyposh.dev/install.sh | sudo bash -s

mkdir ~/.config/omp
if [ -f ~/.config/omp/theme.omp.json ]; then
  wget -q -O - https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/clean-detailed.omp.json >> ~/.config/omp/theme.omp.json
fi

if ! [ -x "$(command -v nginx)"]; then
  echo "
    Installing NGINX
  "
  sudo apt install nginx -y
  sudo cat > /home/$USER/.dev/nginx.conf <<EOF
  user $USER;
worker_processes auto;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	types_hash_max_size 2048;
	# server_tokens off;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log;

	##
	# Gzip Settings
	##

	gzip on;

	# gzip_vary on;
	# gzip_proxied any;
	# gzip_comp_level 6;
	# gzip_buffers 16 8k;
	# gzip_http_version 1.1;
	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /home/$USER/.dev/sites-enabled/*;
}
EOF
  sudo cat > /etc/systemd/system/user-nginx.service <<EOF
  # Stop dance for nginx
# =======================
#
# ExecStop sends SIGQUIT (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /home/$USER/.dev/nginx.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /home/$USER/.dev/nginx.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target

EOF
  sudo systemctl stop nginx
  sudo systemctl disable nginx

  sudo systemctl start user-nginx
  sudo systemctl enable user-nginx
fi


PHP_VERSION=8.3
if ! [ -x "$(command -v php)" ]; then
  echo "
        Installing PHP $PHP_VERSION and required extensions for Laravel...
  "
  sudo apt install "php$PHP_VERSION-fpm" -y
  sudo apt install "php$PHP_VERSION" \
    "php$PHP_VERSION-cli" \
    "php$PHP_VERSION-intl" \
    "php$PHP_VERSION-common" \
    "php$PHP_VERSION-mysql" \
    "php$PHP_VERSION-sqlite3" \
    "php$PHP_VERSION-zip" \
    "php$PHP_VERSION-gd" \
    "php$PHP_VERSION-mbstring" \
    "php$PHP_VERSION-curl" \
    "php$PHP_VERSION-xml" \
    "php$PHP_VERSION-dev" \
    "php$PHP_VERSION-bcmath" -yqq
fi

if ! [ -x "$(command -v composer)" ]; then
  echo "
        Installing Composer...
  "
  curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer
  echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

if ! [ -x "$(command -v laravel)" ]; then
  echo "
        Installing Laravel Installer...
  "
  composer global require laravel/installer
fi

# Install MySQL and set up a default user
if ! [ -x "$(command -v mysql)" ]; then
  echo "
        Installing MariaDB...
  "
  sudo apt install mariadb-server -y
  sudo mysql -e "alter user root@localhost identified via '';FLUSH PRIVILEGES;"
fi

if ! [ -x "$(command -v node)" ]; then
  echo "
        Installing NVM, Node.js, and Yarn...
  "
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  echo "
        Installing Node 20...
  "
  nvm install 20
  npm install -g yarn
  yarn config set -- --emoji true
fi

echo "
        Setting up some alias and functions in your .bashrc
"

wget -q -O - https://raw.githubusercontent.com/clebsonsh/dev-setup/main/dev_bashrc >> ~/.dev_bashrc

if ! grep -q ".dev_bashrc" ~/.bashrc; then
  echo "
    if [ -f ~/.bash_aliases ]; then
      . ~/.bash_aliases
    fi
  " >> ~/.bashrc
fi

echo "
        All set! Happy coding!
        run 'source ~/.bashrc' to reload system paths
"
