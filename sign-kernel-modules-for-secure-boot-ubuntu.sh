#!/bin/bash

### help
while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
   esac
done

### check prerequisites

### Read the secret to decode the key

read -s KBUILD_SIGN_PIN

### find the sign-file script

SIGNEXEC=$(find / -name sign-file 2> /dev/null | grep -s $(uname -a | awk '{print $3}'))

### execute the sign
cd /usr/lib/modules/$(uname -r)/updates/dkms
sudo --preserve-env=KBUILD_SIGN_PIN $SIGNEXEC sha256 /var/lib/shim-signed/mok/MOK{.priv,.der} $0