#!/bin/bash

# Stop script on any error
set -e

echo "Starting installation of CI/CD tools..."

# 1. Update System & Install Basics
echo "--- Updating system and installing dependencies ---"
sudo apt-get update
sudo apt-get install -y wget apt-transport-https gnupg lsb-release python3-pip

# 2. Install Java (OpenJDK 21)
echo "--- Installing Java (OpenJDK 21) ---"
sudo apt install -y fontconfig openjdk-21-jre
java -version

# 3. Install Jenkins
echo "--- Installing Jenkins ---"
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# 4. Install Trivy
echo "--- Installing Trivy ---"
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# 5. Install Checkov (Updated flags)
echo "--- Installing Checkov ---"
sudo pip3 install checkov --break-system-packages --ignore-installed

# 7. Install Terraform
echo "--- Installing Terraform ---"
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform
terraform --version

# 6. Fetch Jenkins Password
echo "--- Waiting for Jenkins to initialize to fetch password... ---"
# Loop to wait for the password file to be generated (max 60 seconds)
for i in {1..12}; do
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        echo "Jenkins initialized!"
        break
    fi
    echo "Waiting for password file..."
    sleep 5
done

echo "=================================================="
echo "       JENKINS INITIAL ADMIN PASSWORD             "
echo "=================================================="
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Error: Password file not found yet. Try: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi
echo "=================================================="

echo "--- Installation Complete! ---"
echo "Trivy Version:"
trivy --version
echo "Checkov Version:"
checkov --version#!/bin/bash

# Stop script on any error
set -e

echo "Starting installation of CI/CD tools..."

# 1. Update System & Install Basics
echo "--- Updating system and installing dependencies ---"
sudo apt-get update
sudo apt-get install -y wget apt-transport-https gnupg lsb-release python3-pip

# 2. Install Java (OpenJDK 21)
echo "--- Installing Java (OpenJDK 21) ---"
sudo apt install -y fontconfig openjdk-21-jre
java -version

# 3. Install Jenkins
echo "--- Installing Jenkins ---"
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# 4. Install Trivy
echo "--- Installing Trivy ---"
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# 5. Install Checkov (Updated flags)
echo "--- Installing Checkov ---"
sudo pip3 install checkov --break-system-packages --ignore-installed

# 6. Fetch Jenkins Password
echo "--- Waiting for Jenkins to initialize to fetch password... ---"
# Loop to wait for the password file to be generated (max 60 seconds)
for i in {1..12}; do
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        echo "Jenkins initialized!"
        break
    fi
    echo "Waiting for password file..."
    sleep 5
done

echo "=================================================="
echo "       JENKINS INITIAL ADMIN PASSWORD             "
echo "=================================================="
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    sudo cat /var/lib/jenkins/secrets/initialAdminPassword
else
    echo "Error: Password file not found yet. Try: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
fi
echo "=================================================="

echo "--- Installation Complete! ---"
echo "Trivy Version:"
trivy --version
echo "Checkov Version:"
checkov --version
