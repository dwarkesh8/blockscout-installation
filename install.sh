#!/bin/bash

# BlockScout installation script for Ubuntu 20.04

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

# Configure PostgreSQL
sudo -u postgres psql -c "CREATE USER blockscout WITH PASSWORD 'blockscout';"
sudo -u postgres psql -c "ALTER USER blockscout WITH SUPERUSER;"
sudo -u postgres psql -c "CREATE DATABASE blockscout OWNER blockscout;"

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
