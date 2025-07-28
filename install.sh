#!/bin/bash

# Load environment variables
. bugzilla.env

set -e

echo "[+] Updating and installing dependencies..."
sudo apt update && sudo apt install -y \
  apache2 mariadb-server libapache2-mod-perl2 \
  libdbi-perl libdbd-mysql-perl libtemplate-perl libdatetime-perl \
  libemail-send-perl libemail-mime-perl libmime-tools-perl \
  libgd-perl libchart-perl git build-essential \
  libssl-dev libexpat1-dev libxml-parser-perl libapache2-mod-perl2-dev \
  libmysqlclient-dev make

echo "[+] Cloning Bugzilla..."
git clone https://github.com/bugzilla/bugzilla.git /var/www/html/bugzilla
cd /var/www/html/bugzilla

echo "[+] Configuring MySQL..."
sudo systemctl start mariadb

sudo mysql -u root <<EOF
CREATE DATABASE ${BUGZILLA_DB};
CREATE USER '${BUGZILLA_USER}'@'localhost' IDENTIFIED BY '${BUGZILLA_PASSWORD}';
GRANT ALL PRIVILEGES ON ${BUGZILLA_DB}.* TO '${BUGZILLA_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[+] Installing Bugzilla dependencies..."
sudo ./checksetup.pl --check-modules
sudo perl install-module.pl --all

echo "[+] Running Bugzilla setup..."
sudo ./checksetup.pl

echo "[+] Copying Apache config..."
sudo cp ~/apache-bugzilla.conf /etc/apache2/sites-available/bugzilla.conf
sudo a2ensite bugzilla.conf
sudo a2enmod cgi headers expires
sudo systemctl reload apache2

echo "[+] Bugzilla installed successfully at http://<your-ec2-public-ip>/bugzilla"
