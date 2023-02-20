#!/bin/bash

### Help
if [ $# -eq 0 ]; then
    echo "No arguments provided"
    echo "You should give the module name you want to sign"
    exit 1
elif [ $# -gt 1 ]; then
    echo "Only one argument available"
    exit 1
fi

### root privileges required
if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo or as root"
  exit 1
fi

### Regex on the module name
if [[ $1 =~ \.ko$ ]]; then
  modinfovar=$(echo $1 | sed s/\.[^.]*$//)
else 
  modinfovar=$1
fi

if ! [[ $1 =~ \.ko$ ]]; then
  modsignvar=$(echo $1.ko)
else
  modsignvar=$1
fi

### Is file already signed 
modinfocmd=$(/usr/sbin/modinfo -F signer $modinfovar)
if [[ -n $modinfocmd ]]; then 
  echo "Module $1 already signed"
  exit 0 
else 
  echo "Module not signed, can continue"
fi

### Check prerequisites
# is key loaded
filter=$(echo "Subject: CN=$(hostname -s | cut -b1-31) Secure Boot Module Signature key")
mokutil --list-enrolled | grep "$filter" > /dev/null 2>&1
if [ $? -eq 0 ]; then 
  echo "Signing key already loaded, can continue" 
else 
  echo "Error key not loaded. You should considere the use of prerequisites.sh"
  exit 1 
fi
# find required file to sign
SIGNEXEC=$(find / -name sign-file 2> /dev/null | grep -s $(uname -a | awk '{print $3}'))
PRIVFILE=$(sudo find / -name MOK.priv 2> /dev/null)
DERFILE=$(sudo find / -name MOK.der 2> /dev/null)

dpkg -l |grep shim-signed > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Signing utility not found, you may have to install shim-signed package"
  exit 1
elif [ -z $PRIVFILE ]; then
  echo "Error private key not found. You should considere the use of prerequisites.sh"
  exit 1
elif [ -z $DERFILE ]; then
  echo "Error DER certificate not found. You should considere the use of prerequisites.sh"
  exit 1
else
  echo "Prerequisite found, can continue"
fi

### Execute the sign
# Read the passphrase to decode the key
read -sp "Passphrase to load private key:" KBUILD_SIGN_PIN

cd /usr/lib/modules/$(uname -r)/updates/dkms
sudo KBUILD_SIGN_PIN=$KBUILD_SIGN_PIN $SIGNEXEC sha256 $PRIVFILE $DERFILE $modsignvar
cd - > /dev/null 2>&1

### Verify if module is ready to be loaded
modinfocmdbis=$(/usr/sbin/modinfo -F signer $modinfovar)
if [[ -n $modinfocmdbis ]]; then
  echo "Module kindly signed"
  exit 0
else
  echo "Error, module not signed"
fi


