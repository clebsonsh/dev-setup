#!/bin/bash
set -e

echo "
        This script automates the installation of the essential components required for Full-Stack Laravel development:

          - Ubuntu 24.04
          - PHP 8.3
          - Node 22
          - Composer
          - Nginx
          - MariaDB (user: root with no password)
          - Laravel Installer
          - NVM (Node Version Manager)
          - Yarn
        
        you will be prompt for sudo password a few times
"

sleep 5

sudo add-apt-repository universe -y

echo "
        Updating system packages...
"
sudo apt update
sudo apt upgrade -y

echo "
        Installing basic tools...
"
wget https://raw.githubusercontent.com/clebsonsh/dev-setup/main/addsite.sh
sudo mv addsite.sh /usr/local/bin/addsite
sudo chmod +x /usr/local/bin/addsite

wget https://raw.githubusercontent.com/clebsonsh/dev-setup/main/rmsite.sh
sudo mv rmsite.sh /usr/local/bin/rmsite
sudo chmod +x /usr/local/bin/rmsite

sudo apt install htop curl git vim unzip -y

echo "
        Installing NGINX
"
sudo apt install nginx -y
sudo sed -i "s/www-data/$USER/" /etc/nginx/nginx.conf

sudo systemctl restart nginx

PHP_VERSION=8.3
if ! [ -x "$(command -v php)" ]; then
  echo "
        Installing PHP $PHP_VERSION and required extensions for Laravel...
  "
  sudo apt install "php$PHP_VERSION-fpm" -y
  sudo -S apt install -y \
    "php$PHP_VERSION" \
    "php$PHP_VERSION-cli" \
    "php$PHP_VERSION-intl" \
    "php$PHP_VERSION-common" \
    "php$PHP_VERSION-mysql" \
    "php$PHP_VERSION-sqlite3" \
    "php$PHP_VERSION-swoole" \
    "php$PHP_VERSION-zip" \
    "php$PHP_VERSION-gd" \
    "php$PHP_VERSION-mbstring" \
    "php$PHP_VERSION-curl" \
    "php$PHP_VERSION-xml" \
    "php$PHP_VERSION-dev" \
    "php$PHP_VERSION-bcmath"
fi

sudo sed -i "s/www-data/$USER/" /etc/php/8.3/fpm/pool.d/www.conf

sudo systemctl restart php8.3-fpm

if ! [ -x "$(command -v composer)" ]; then
  echo "
        Installing Composer...
  "
  curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer
  echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >>~/.bashrc
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
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  echo "
        Installing Node 22...
  "
  nvm install 22
  npm install -g npm
  npm install -g yarn
  yarn config set -- --emoji true
fi

echo "
        All set! Happy coding!
        run 'source ~/.bashrc' to reload system paths
"
