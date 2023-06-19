#!/bin/bash

# BlockScout installation script for Ubuntu 20.04

# Function to check if a port is open
check_port() {
  nc -z localhost "$1"
  return $?
}

# Update system packages
sudo apt update

# Install required packages
sudo apt install -y curl git postgresql postgresql-contrib

# Install Elixir and Erlang
sudo apt install -y esl-erlang elixir

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
    echo "Port 4000 has been opened. Continuing with the installation."
  else
    echo "Port 4000 needs to be open for BlockScout. Aborting installation."
    exit 1
  fi
fi

# Configure PostgreSQL
read -p "Enter PostgreSQL username: " pg_username
read -s -p "Enter PostgreSQL password: " pg_password
echo

sudo -u postgres psql -c "CREATE USER $pg_username WITH PASSWORD '$pg_password';"
sudo -u postgres psql -c "ALTER USER $pg_username WITH SUPERUSER;"
sudo -u postgres psql -c "CREATE DATABASE blockscout OWNER $pg_username;"

# Install dependencies
mix do deps.get, compile

# Configure BlockScout
cp config/dev.exs config/dev.secret.exs
# Edit the config/dev.secret.exs file to provide your custom configuration

# Create and migrate the database
mix do ecto.create, ecto.migrate

# Install Node.js dependencies
cd assets
yarn

# Build assets
yarn run build

# Start BlockScout
mix phx.server
