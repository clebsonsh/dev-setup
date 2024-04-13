#!/bin/bash
set -e
PHP_VERSION="8.3"

if ! grep -q "^deb .*universe" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  echo "adding universe repository..."
  sudo add-apt-repository universe -y
fi

if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  echo "adding ondrej/php ppa repository..."
  sudo add-apt-repository ppa:ondrej/php -y
fi

sudo apt update
sudo apt upgrade -y

if ! [ -x "$(command -v git)" ]; then
  echo "installing git..."
  sudo apt install git -y
fi

if ! [ -x "$(command -v vim)" ]; then
  echo "installing vim..."
  sudo apt install vim -y
fi

if ! [ -x "$(command -v network-manager)" ]; then
  sudo apt install network-manager -y
fi

if ! [ -x "$(command -v libnss3-tools)" ]; then
  sudo apt install libnss3-tools -y
fi

if ! [ -x "$(command -v jq)" ]; then
  echo "installing jq..."
  sudo apt install jq -y
fi

if ! [ -x "$(command -v xsel)" ]; then
  echo "installing xsel..."
  sudo apt install xsel -y
fi

if ! [ -x "$(command -v curl)" ]; then
  echo "installing curl..."
  sudo apt install curl -y
fi

if ! [ -x "$(command -v unzip)" ]; then
  echo "installing unzip..."
  sudo apt install unzip -y
fi

if ! [ -x "$(command -v php)" ]; then
  echo "installing PHP$PHP_VERSION..."
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

if ! [ -x "$(command -v composer)" ]; then
  echo "installing Composer..."
  curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/
  sudo ln -s /usr/local/bin/composer.phar /usr/local/bin/composer
  echo 'export PATH="$HOME/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
fi

if ! [ -x "$(command -v valet)" ]; then
  echo "installing Laravel Valet..."
  composer global require cpriego/valet-linux
  export PATH="$HOME/.config/composer/vendor/bin:$PATH"
  valet install
fi

if ! [ -x "$(command -v laravel)" ]; then
  echo "installing Laravel Installer..."
  composer global require laravel/installer
fi

if ! [ -x "$(command -v mysql)" ]; then
  echo "installing MySQL..."
  sudo apt install mysql-server -y
  sudo mysql -e "CREATE USER 'sail'@localhost IDENTIFIED BY 'password';GRANT ALL PRIVILEGES ON *.* TO 'sail'@localhost;FLUSH PRIVILEGES;"
fi

if ! [ -x "$(command -v redis-server)" ]; then
  echo "installing Redis..."
  sudo apt install redis-server -y
fi

if ! [ -x "$(command -v node -v)" ]; then
  echo "installing NVM, Node and Yarn..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm install 20
  npm install -g yarn
  yarn config set -- --emoji true
fi

if ! [ -x "$(command -v code)" ]; then
  echo "installing VSCode..."

  sudo apt-get install gpg -y
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg
  sudo apt install apt-transport-https -y
  sudo apt update
  sudo apt install code -y
fi
