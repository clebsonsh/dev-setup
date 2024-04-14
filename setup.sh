#!/bin/bash
set -e

echo "
  This script automates the installation of the essential components required for Full-Stack Laravel development:

    - PHP (choose from versions 8.3, 8.2, 8.1, 8.0, 7.4)
    - Composer
    - Nginx
    - MySQL
    - Laravel Valet
    - Laravel Installer
    - NVM (Node Version Manager)
    - Node.js
    - Yarn
"

# Select PHP version if PHP is not already installed
if ! [ -x "$(command -v php)" ]; then
  echo "
    Select a PHP version to install...
  "
  select PHP_VERSION in "8.3" "8.2" "8.1" "8.0" "7.4"
  do
    if ! [ -z "$PHP_VERSION" ]
    then
      echo "
        Installing PHP $PHP_VERSION...
      "
      break
    fi
  done
fi

# Add required repositories if not already added
if ! grep -q "^deb .*universe" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  echo "
    Adding 'universe' repository...
  "
  sudo add-apt-repository universe -y
fi

if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  echo "
    Adding 'ondrej/php' PPA repository...
  "
  sudo add-apt-repository ppa:ondrej/php -y
fi

# Update system packages
echo "
  Updating system packages...
"
sudo apt update
sudo apt upgrade -y

# Install/update Laravel Valet dependencies
echo "
  Installing/updating dependencies for Laravel Valet...
"
sudo apt install git vim network-manager libnss3-tools jq xsel curl unzip -y

# Install PHP and required PHP extensions
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
    "php$PHP_VERSION-swoole" \
    "php$PHP_VERSION-zip" \
    "php$PHP_VERSION-gd" \
    "php$PHP_VERSION-mbstring" \
    "php$PHP_VERSION-curl" \
    "php$PHP_VERSION-xml" \
    "php$PHP_VERSION-dev" \
    "php$PHP_VERSION-redis" \
    "php$PHP_VERSION-bcmath" -yqq
fi

# Install Composer
if ! [ -x "$(command -v composer)" ]; then
  echo "
    Installing Composer...
  "
  curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer
  sudo ln -s /usr/local/bin/composer.phar /usr/local/bin/composer
  echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

# Install Laravel Valet
if ! [ -x "$(command -v valet)" ]; then
  echo "
    Installing Laravel Valet...
  "
  composer global require cpriego/valet-linux
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
  valet install
fi

# Install Laravel Installer
if ! [ -x "$(command -v laravel)" ]; then
  echo "
    Installing Laravel Installer...
  "
  composer global require laravel/installer
fi

# Install MySQL and set up a default user
if ! [ -x "$(command -v mysql)" ]; then
  echo "
    Installing MySQL...
  "
  sudo apt install mysql-server -y
  echo "
    Creating MySQL user:
    username: sail
    password: password
  "
  sudo mysql -e "CREATE USER 'sail'@localhost IDENTIFIED BY 'password';GRANT ALL PRIVILEGES ON *.* TO 'sail'@localhost;FLUSH PRIVILEGES;"
fi

# Install Redis
if ! [ -x "$(command -v redis-server)" ]; then
  echo "
    Installing Redis...
  "
  sudo apt install redis-server -y
fi

# Install NVM, Node.js, and Yarn
if ! [ -x "$(command -v node)" ]; then
  echo "
    Installing NVM, Node.js, and Yarn...
  "
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm install node
  npm install -g yarn
  yarn config set -- --emoji true
fi
