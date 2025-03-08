#!/bin/bash
set -e
echo -e "transparent-tor 0.2.1"
echo -e "Author: vnmdcvpfug"
echo -e "Source: https://github.com/vnmdcvpfug/transparent-tor\n"
echo -e "Welcome to the transparent-tor installation script. It can:\n"
echo -e "1) Route your internet traffic through Tor."
echo -e "2) Configure Tor as a proxy.\n"
echo -e "Please note that this script will not provide 100% privacy. Use with caution."
echo -n "It is intended for a freshly installed Arch Linux system. Proceed? [y/N]: "; read choice_begin

if [ "$choice_begin" == "y" ] || [ "$choice_begin" == "Y" ] || [ "$choice_begin" == "yes" ] || [ "$choice_begin" == "Yes" ] || [ "$choice_begin" == "YES" ]; then
  echo -e "\nWhat do you want to do?"
  echo -e "1) Route your internet traffic through Tor (Recommended)."
  echo -e "2) Configure Tor as a proxy."
  echo -n "Pick 1 or 2: "; read choice_number
else
  exit 0
fi

if [ "$choice_number" == 1 ]; then
  echo -en "\nThis script will route your internet traffic through Tor. Proceed? [Y/n]: ";read choice_transparent
elif [ "$choice_number" == 2 ]; then
  echo -en "\nThis script will configure Tor as a proxy. Proceed? [Y/n]: "; read choice_proxy
else
  exit 0
fi

if [ "$choice_transparent" == "y" ] || [ "$choice_transparent" == "Y" ] || [ "$choice_transparent" == "yes" ] || [ "$choice_transparent" == "Yes" ] || [ "$choice_transparent" == "YES" ] || [ "$choice_transparent" == "" ]; then
  # install obfs4
  echo -e "\nInstalling obfs4..."
  sudo pacman -S go
  mkdir -p ~/opt
  cd ~/opt
  git clone https://github.com/Yawning/obfs4.git
  cd ~/opt/obfs4
  go build -o obfs4proxy/obfs4proxy ./obfs4proxy
  sudo cp -r ./obfs4proxy/obfs4proxy /usr/bin/obfs4proxy
  sudo pacman -Rns go
  sudo rm -fr ~/go

  # configure tor
  echo -e "\nConfiguring tor..."
  cd ~/transparent-tor
  sudo pacman -S tor
  sudo cp -r ~/transparent-tor/torrc /etc/tor/torrc
  sudo systemctl enable --now tor

  # configure iptables
  echo -e "\nConfiguring iptables..."
  sudo cp -r ~/transparent-tor/05_proxy /etc/sudoers.d/05_proxy
  sudo cp -r ~/transparent-tor/iptables.rules /etc/iptables/iptables.rules
  sudo rm /etc/iptables/ip6tables.rules
  sudo ln -s /etc/iptables/iptables.rules /etc/iptables/ip6tables.rules
  sudo systemctl enable --now iptables
  sudo systemctl enable --now ip6tables
  sudo systemctl restart tor
  
  # configure DNS resolver
  echo -e "\nConfiguring DNS resolver..."
  sudo echo -e "[main]\ndns=systemd-resolved" | sudo tee /etc/NetworkManager/conf.d/dns.conf > /dev/null
  sudo mkdir -p /etc/systemd/resolved.conf.d
  sudo echo -e "[Resolve]\nDNS=127.0.0.1\nDomains=~." | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf > /dev/null
  sudo systemctl enable --now systemd-resolved
  sudo systemctl restart NetworkManager
  
  # the installation is complete
  echo -e "\nThe installation is complete."
else
  exit 0
fi

if [ "$choice_proxy" == "y" ] || [ "$choice_proxy" == "Y" ] || [ "$choice_proxy" == "yes" ] || [ "$choice_proxy" == "Yes" ] || [ "$choice_proxy" == "YES" ] || [ "$choice_proxy" == ""]; then
  # configure environment
  sudo cp -r ~/dotfiles/environment /etc/environment
  echo -e "\nThe installation is complete."
else
  exit 0
fi
