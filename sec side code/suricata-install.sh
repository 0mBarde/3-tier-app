#!/bin/bash

# 1. Update and Install Build Dependencies
echo "Installing build dependencies..."
sudo dnf groupinstall "Development Tools" -y
sudo dnf install -y libpcap-devel libcap-ng-devel libyaml-devel zlib-devel \
    pcre2-devel libnet-devel nss-devel lz4-devel jansson-devel \
    python3-devel rust cargo file-devel wget

# 2. Download and Extract Suricata 7.0.2
echo "Downloading Suricata 7.0.2..."
wget https://www.openinfosecfoundation.org/download/suricata-7.0.2.tar.gz
tar -xvzf suricata-7.0.2.tar.gz
cd suricata-7.0.2

# 3. Configure with necessary paths
echo "Configuring build..."
./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var

# 4. Compile and Install
echo "Compiling (this may take a few minutes)..."
make
sudo make install

# 5. Install default configuration files
echo "Installing configuration files..."
sudo make install-conf

# 6. Initialize Rule Engine
echo "Updating rules..."
sudo suricata-update

# 7. Setup Log Directory Permissions
echo "Setting up log directory..."
sudo mkdir -p /var/log/suricata
sudo chmod 755 /var/log/suricata

echo "--------------------------------------------------"
echo "Installation Complete!"
echo "Verify with: suricata -V"
echo "Check Magic support: suricata --build-info | grep magic"
echo "--------------------------------------------------"
