#!/bin/bash
set -e

if ! [ -x "$(command -v jq)" ]; then
  sudo apt install jq tmux htop -y &> /dev/null
fi

data=$(curl 'https://php.watch/api/v1/versions' -s)
php_supported_versions=($(echo $data | jq ".. | select((.statusLabel? != \"Unsupported\") and .statusLabel? != \"Upcoming Release\").name" | jq "select(. != null)"))

echo "
        This script automates the installation of the essential components required for Full-Stack Laravel development:

          - PHP (choose from supported versions ${php_supported_versions[@]})
          - Composer
          - Nginx
          - MariaDB
          - Laravel Valet
          - Laravel Installer
          - NVM (Node Version Manager)
          - Node.js
          - Yarn
"

sleep 3

# Add required repositories if not already added
if ! grep -q "^deb .*universe" /etc/apt/sources.list; then
  echo "
        Adding 'universe' repository...
  "
  sudo add-apt-repository universe -y
fi

if ! [ -e "/etc/apt/sources.list.d/ondrej-ubuntu-php-jammy.list" ]; then
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

# Select PHP version if PHP is not already installed
if ! [ -x "$(command -v php)" ]; then
  echo "
        Select a supported PHP version to install...
  "
  select PHP_VERSION in "${php_supported_versions[@]}"
  do
    if ! [ -z "$PHP_VERSION" ]; then
      PHP_VERSION="$(echo $PHP_VERSION | sed 's/\"//g')"
      echo "
        Installing PHP $PHP_VERSION...
      "
      break
    fi
  done
fi

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
        Installing MariaDB...
  "
  sudo apt install mariadb-server -y
  echo "
        Creating MariaDB user:
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
  echo "
        Installing Node 12...
  "
  nvm install 12
  npm install -g yarn
  yarn config set -- --emoji true
  echo "
        Installing Node 14...
  "
  nvm install 14
  npm install -g yarn
  yarn config set -- --emoji true
  echo "
        Installing Node 16...
  "
  nvm install 16
  npm install -g yarn
  yarn config set -- --emoji true
  echo "
        Installing Node 18...
  "
  nvm install 18
  npm install -g yarn
  yarn config set -- --emoji true
  echo "
        Installing Node 20...
  "
  nvm install 20
  npm install -g yarn
  yarn config set -- --emoji true
fi

echo "
        Setting up some alias in your .bashrc
"

wget -q -O - https://raw.githubusercontent.com/clebsonsh/dev-setup/main/bashrc >> ~/.bashrc

echo "
        All set! Happy coding!
        run 'source ~/.bashrc' to reload system paths
"
