# Bugzilla Installation Script on Ubuntu 22.04 (No Domain)

set -e

# Load config
source bugzilla.env

# Update packages
sudo apt update -y && sudo apt upgrade -y

# Install required packages
sudo apt install apache2 mariadb-server libapache2-mod-perl2 \
    libdbi-perl libdbd-mysql-perl libtemplate-perl libdatetime-perl \
    libemail-send-perl libemail-mime-perl libmime-tools-perl \
    libgd-perl libchart-perl git unzip build-essential -y

# Enable required Apache modules
sudo a2enmod cgi
sudo systemctl restart apache2

# Configure MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

sudo mysql -e "CREATE DATABASE ${BUGZILLA_DB} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
sudo mysql -e "CREATE USER '${BUGZILLA_USER}'@'localhost' IDENTIFIED BY '${BUGZILLA_PASSWORD}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${BUGZILLA_DB}.* TO '${BUGZILLA_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Download Bugzilla
sudo mkdir -p /var/www/html/bugzilla
cd /tmp
wget https://ftp.mozilla.org/pub/mozilla.org/webtools/bugzilla/latest.tar.gz
sudo tar -xvzf latest.tar.gz -C /var/www/html/bugzilla --strip-components=1
cd /var/www/html/bugzilla

# Install Bugzilla Perl modules
sudo /usr/bin/perl install-module.pl --all

# Configure Bugzilla
sudo ./checksetup.pl

# Create localconfig file
sudo sed -i "s/'db_name' => 'bugs'/'db_name' => '${BUGZILLA_DB}'/" localconfig
sudo sed -i "s/'db_user' => 'bugs'/'db_user' => '${BUGZILLA_USER}'/" localconfig
sudo sed -i "s/'db_pass' => ''/'db_pass' => '${BUGZILLA_PASSWORD}'/" localconfig

# Final setup
sudo ./checksetup.pl --check-modules
sudo ./checksetup.pl

# Set permissions
sudo chown -R www-data:www-data /var/www/html/bugzilla

# Apache config
sudo cp ../apache-bugzilla.conf /etc/apache2/sites-available/bugzilla.conf
sudo a2ensite bugzilla.conf
sudo systemctl reload apache2

# Enable firewall (optional)
sudo ufw allow 80
sudo ufw --force enable

# Done
echo "Bugzilla installation complete! Access it via: http://<your-ec2-public-ip>/bugzilla/"

