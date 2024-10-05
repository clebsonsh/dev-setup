#!/bin/bash
set -e

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
        
        you will be prompt for sudo password a few times
"

sleep 5

sudo add-apt-repository universe -y

if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list 2>/dev/null; then
  sudo -S add-apt-repository ppa:ondrej/php -y
fi

echo "
        Updating system packages...
"
sudo apt update
sudo apt upgrade -y

echo "
        Installing basic tools...
"
wget https://raw.githubusercontent.com/clebsonsh/dev-setup/main/add-site
sudo mv add-site /usr/local/bin/add-site
sudo chmod +x /usr/local/bin/add-site

sudo apt install htop curl git vim unzip -y
curl -s https://ohmyposh.dev/install.sh | bash -s

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

# Add the signature to trust the Microsoft repo
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc

# Add repo to apt sources
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

# Install the driver
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >>~/.bashrc
source ~/.bashrc
# optional: for unixODBC development headers
sudo apt-get install -y unixodbc-dev

sudo pecl install -f sqlsrv
sudo pecl install -f pdo_sqlsrv

printf "; priority=20\nextension=sqlsrv.so\n" >sqlsrv.ini
sudo mv sqlsrv.ini /etc/php/8.3/mods-available/sqlsrv.ini
printf "; priority=30\nextension=pdo_sqlsrv.so\n" >pdo_sqlsrv.ini
sudo mv pdo_sqlsrv.ini /etc/php/8.3/mods-available/pdo_sqlsrv.ini
sudo phpenmod -v 8.3 sqlsrv pdo_sqlsrv

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
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
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
        All set! Happy coding!
        run 'source ~/.bashrc' to reload system paths
"
