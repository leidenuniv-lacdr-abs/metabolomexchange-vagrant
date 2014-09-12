# install a MetabolomExchange Dev machine

apt-get update

# install Apache
apt-get install -y apache2

a2enmod rewrite #enable mod-rewrite
cat > /etc/apache2/sites-available/000-default.conf << EOF
<VirtualHost *:80>
        ServerName localhost
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        <Directory "/var/www/html">
    		AllowOverride All
		</Directory>
</VirtualHost>
EOF

cat >> /etc/apache2/apache2.conf << EOF
ServerName localhost
EOF
rm -rf /var/www
rm -rf /vagrant/source-mx
rm -rf /vagrant/source-mx-feeds
ln -fs /vagrant /var/www

# install MongoDB
apt-get install -y mongodb
service mongodb restart
cat > /vagrant/mongousers.js << EOF
	db.addUser('mongoadminusername','mongoadminpassword');
	db.addUser('mongousername','mongopassword');
EOF
mongo metabolomexchange /vagrant/mongousers.js

# install GIT
apt-get install -y git-core

# install nano
apt-get install -y nano

# install lynx
apt-get install -y lynx

# install PHP
apt-get install -y php5 libapache2-mod-php5
apt-get install -y php-pear php5-dev
pecl search mongo
printf "\n" | pecl install mongo

# enable mongo.so
rm -rf /etc/php5/apache2/conf.d/mongo.ini
touch /etc/php5/apache2/conf.d/mongo.ini
cat > /etc/php5/apache2/conf.d/mongo.ini << EOF
; configuration for php MONGO module
extension=mongo.so
EOF

# download latest version of mx
git clone https://github.com/leidenuniv-lacdr-abs/metabolomexchange.git /var/www/source-mx
git clone https://github.com/leidenuniv-lacdr-abs/metabolomexchange-feeds.git /var/www/source-mx-feeds

ln -s /var/www/source-mx /var/www/html
ln -s /var/www/source-mx-feeds /var/www/html/feeds
ln -s /tmp /var/www/html/tmp

# correct the links to the feeds
sed -i "s/feeds.metabolomexchange.org/localhost\/feeds/g" /var/www/source-mx/providers.json
sed -i "s/golm.php/source-mx-feeds\/php-golm-feed\/index.php/g" /var/www/source-mx/providers.json
sed -i "s/metabolights.php/source-mx-feeds\/php-metabolights-feed\/index.php/g" /var/www/source-mx/providers.json
sed -i "s/meryb.php/source-mx-feeds\/php-meryb-feed\/index.php/g" /var/www/source-mx/providers.json
sed -i "s/metabolomics-workbench.php/source-mx-feeds\/php-metabolomics-workbench-feed\/index.php/g" /var/www/source-mx/providers.json

# fix documentation calls to point to internal url when calling the api
sed -i "s/url\ =/url\ =\ \'http:\/\/localhost'\;\ \/\//g" /var/www/source-mx/views/documentation.php

# set cache to go to /tmp
sed -i "s/cacheDir = /cacheDir = \'\/tmp\/cache\';\ \/\//g" /var/www/source-mx/views/documentation.php
sed -i "s/cacheDir = /cacheDir = \'\/tmp\/cache\';\ \/\//g" /var/www/source-mx/views/stats.php

# make cache folder (writable)
mkdir /var/www/html/cache
chmod -R 777 /var/www/html/cache

# restart Apache
service apache2 restart