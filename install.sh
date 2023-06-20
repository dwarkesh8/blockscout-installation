#!/bin/bash

# BlockScout installation script for Ubuntu 20.04

# Function to check if a package is installed
package_installed() {
  dpkg -s "$1" &> /dev/null
  return $?
}

# Function to check if a port is open
check_port() {
  nc -z localhost "$1"
  return $?
}

# Update system packages
sudo apt update
sudo apt upgrade -y

cd /home/
#mkdir blockscout
#cd blockscout

# Install required packages if not already installed
if ! package_installed curl || ! package_installed git || ! package_installed postgresql || ! package_installed postgresql-contrib; then
  sudo apt install -y curl git postgresql postgresql-contrib
else
  echo "Required packages are already installed. Skipping package installation."
fi

# Install Elixir and Erlang if not already installed
if ! package_installed esl-erlang || ! package_installed elixir; then
  # Download and install esl-erlang package
  wget https://packages.erlang-solutions.com/erlang/debian/pool/esl-erlang_24.3.2-1~ubuntu~focal_amd64.deb
  chmod +x esl-erlang_24.3.2-1~ubuntu~focal_amd64.deb
  sudo dpkg -i esl-erlang_24.3.2-1~ubuntu~focal_amd64.deb

  # Install elixir package
  sudo apt install -y elixir
else
  echo "Elixir and Erlang are already installed. Skipping Elixir and Erlang installation."
fi

# Clone BlockScout repository (replace with desired version)
git clone --branch v4.1.4-beta https://github.com/poanetwork/blockscout.git
cd blockscout

# Install Node.js (use Node.js version manager if preferred)
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs

# Install Yarn package manager
sudo npm install -g yarn

# Check if port is open
if check_port 4000; then
  echo "Port 4000 is already open. Continuing with the installation."
else
  read -p "Port 4000 is closed. Would you like to open it? (Y/n) " open_port_choice
  if [[ $open_port_choice =~ ^[Yy]$ ]]; then
    # Open port 4000
    sudo ufw allow 4000
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw enable
    echo "Port 4000 has been opened. Continuing with the installation."
  else
    echo "Port 4000 needs to be open for BlockScout. Aborting installation."
    exit 1
  fi
fi

# Configure PostgreSQL
if package_installed postgresql; then
  echo "PostgreSQL is already installed. Skipping PostgreSQL setup."
else
  read -p "Enter PostgreSQL username: " pg_username
  read -s -p "Enter PostgreSQL password: " pg_password
  echo

  sudo -u postgres psql -c "CREATE USER $pg_username WITH PASSWORD '$pg_password';" || echo "User already exists. Skipping user creation."
  sudo -u postgres psql -c "ALTER USER $pg_username WITH SUPERUSER;" || echo "User already has SUPERUSER privileges. Skipping role alteration."
  sudo -u postgres psql -c "CREATE DATABASE blockscout OWNER $pg_username;" || echo "Database already exists. Skipping database creation."
fi

# Install dependencies
mix do deps.get, compile

# Configure BlockScout
cp config/dev.exs config/dev.secret.exs
# Edit the config/dev.secret.exs file to provide your custom configuration

# Create and migrate the database
mix do ecto.create, ecto.migrate

# Start BlockScout
mix phx.server
