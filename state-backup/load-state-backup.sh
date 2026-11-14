#!/usr/bin/env bash
# Run after fresh install 

# Brave
mkdir -p ~/.config/BraveSoftware/Brave-Browser/Default
cp ~/nixos.files/state-backup/brave/* ~/.config/BraveSoftware/Brave-Browser/Default/

# Okular
cp ~/nixos.files/state-backup/okular/* ~/.config/

# LibreOffice
mkdir -p ~/.config/libreoffice/4/user
cp ~/nixos.files/state-backup/libreoffice/registrymodifications.xcu ~/.config/libreoffice/4/user/

echo "Done"
