#!/bin/bash
set -e
PHP_VERSION="8.3"

if ! grep -q "^deb .*universe" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  sudo add-apt-repository universe -yqq
fi

if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  sudo add-apt-repository ppa:ondrej/php -yqq
fi

sudo apt update

sudo apt upgrade -y

if ! [ -x "$(command -v git)" ]; then
  sudo apt install vim git network-manager libnss3-tools jq xsel curl unzip -y
fi

if ! [ -x "$(command -v php)" ]; then
  sudo apt install "php$PHP_VERSION-fpm" -y
  sudo apt install "php$PHP_VERSION" \
    "php$PHP_VERSION-cli" \
    "php$PHP_VERSION-intl" \
    "php$PHP_VERSION-common" \
    "php$PHP_VERSION-mysql" \
    "php$PHP_VERSION-zip" \
    "php$PHP_VERSION-gd" \
    "php$PHP_VERSION-mbstring" \
    "php$PHP_VERSION-curl" \
    "php$PHP_VERSION-xml" \
    "php$PHP_VERSION-dev" \
    "php$PHP_VERSION-redis" \
    "php$PHP_VERSION-bcmath" -yqq
fi

if ! [ -x "$(command -v composer)" ]; then
  curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/
  sudo ln -s /usr/local/bin/composer.phar /usr/local/bin/composer
  echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

if ! [ -x "$(command -v valet)" ]; then
  composer global require cpriego/valet-linux
  valet install
fi

if ! [ -x "$(command -v mysql)" ]; then
  sudo apt install mysql-server -y
  sudo mysql -e "CREATE USER 'sail'@localhost IDENTIFIED BY 'password';GRANT ALL PRIVILEGES ON *.* TO 'sail'@localhost;FLUSH PRIVILEGES;"
fi

if ! [ -x "$(command -v redis-server)" ]; then
  sudo apt install redis-server -y
fi

if ! [ -x "$(command -v nvm)" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm install 20
  npm install -g yarn
  yarn config set -- --emoji true
fi
