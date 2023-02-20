## Goal

This repo aims to automate the process of signing a module to comply with secure boot
My work in inspired by this blog post: https://www.guyrutenberg.com/2022/09/29/signing-kernel-modules-for-secure-boot/

## How to 

If you never signed a module, you can run the prerequisites that will check for the requirements and create the required keys and certificates.

```bash
sudo ./prerequisites.sh
```

If you already pass through the requirements, you can run sign-kernel-modules-for-secure-boot-ubuntu.sh with the module name you want to sign in first argument

```bash
sudo ./sign-kernel-modules-for-secure-boot-ubuntu.sh v4l2loopback
```

If everything goes well, you can finally run a modprobe for you module

```bash
sudo modprobe v4l2loopback 
```