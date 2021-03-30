#!/usr/bin/env bash
set -e

sudo apt update
sudo apt install curl -y

sudo apt install net-tools -y
# ping
sudo apt install iputils-ping -y

# Build tools
sudo apt install build-essential -y
sudo apt install cmake -y
sudo apt install cscope -y

# CMD line tools
sudo apt install tree -y
sudo apt install mc -y
sudo apt install sudo -y
sudo apt install nload -y
sudo apt install tmux -y
sudo apt install zsh -y
