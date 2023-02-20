#!/bin/bash

### root privileges required
if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo or as root"
  exit 1
fi

### check if we run ubuntu
osversion=$(grep ubuntu /etc/os-release)
if [[ -z $osversion ]]; then
  echo "OS is not Ubuntu, stopping"
  exit 1
fi

### check if files exist
PRIVFILE=$(sudo find / -name MOK.priv 2> /dev/null)
DERFILE=$(sudo find / -name MOK.der 2> /dev/null)

dpkg -l |grep shim-signed > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Signing utility not found, you may have to install shim-signed package"
  exit 1
elif [ -n $PRIVFILE ]; then
  echo "Error Private key found. Stopped to prevent mistakes"
  exit 1
elif [ -n $DERFILE ]; then
  echo "Error DER certificate found. Stopped to prevent mistakes"
  exit 1
fi

### Creating mok folder
mkdir -p /var/lib/shim-signed/mok
cd /var/lib/shim-signed/mok/

### Creating PrivKey and DER Cert

echo "The script will now create key and cert"
echo "!!!!! Remember the passphrase !!!!!"

openssl genrsa -aes256 -out MOK.priv
openssl req \
        -subj "/CN=`hostname -s | cut -b1-31` Secure Boot Module Signature key" \
        -new -x509 -nodes -days 36500 -outform DER \
        -key MOK.priv \
        -out MOK.der

### Explain user the next steps 

echo "The script will now enroll the newly created key with command mokutil --import MOK.der"
echo "You will be prompted for a password."
echo "This password will be required during reboot in order to complete the key enrollment, you will not need it afterwards."

read -p "Enter yes to confirm that you understand the next steps" continue

if [[ $continue == "yes" ]]; then
  mokutil --import MOK.der
  echo "You now have to reboot to complete the process."
  exit 0
else
  echo "you did not type yes"
  exit 1
fi