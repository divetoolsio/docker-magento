MAGENTO_VERSION=$2
MAGENTO_URL=$1

MYSQL_HOST=127.0.0.1:3306
MYSQL_USER=root
MYSQL_PASSWORD=
MYSQL_DATABASE=magento
MAGENTO_LOCALE=en_GB
MAGENTO_TIMEZONE=UTC
MAGENTO_DEFAULT_CURRENCY=GBP
MAGENTO_ADMIN_FIRSTNAME=magento
MAGENTO_ADMIN_LASTNAME=magento
MAGENTO_ADMIN_EMAIL=magento@magento.com
MAGENTO_ADMIN_USERNAME=magento
MAGENTO_ADMIN_PASSWORD=magento123

echo "Waiting for DB to initialise"
sleep 3

#install sample data
echo "Installing sample data"
cd /res && tar xf magento-sample-data-1.9.2.4.tar.gz
cp -R /res/magento-sample-data-1.9.2.4/media/* /www/media/
cp -R /res/magento-sample-data-1.9.2.4/skin/* /www/skin/
chown -R apache:apache /www/media
mysql -u "root" "magento" < /res/magento-sample-data-1.9.2.4/magento_sample_data_for_1.9.2.4.sql

#install magento
echo "Installing magento"
php -f /www/install.php -- --license_agreement_accepted "yes" --locale "en_GB" --timezone "UTC" --default_currency "GBP" --db_host "127.0.0.1" --db_name "magento" --db_user "root" --db_pass "" --url $MAGENTO_URL --skip_url_validation "yes" --use_rewrites "yes" --use_secure "no" --secure_base_url "" --use_secure_admin "no" --admin_firstname "magento" --admin_lastname "magento" --admin_email "magento@magento.com" --admin_username "magento" --admin_password "magento123"
chmod -R 777 /www

#echo "Magento $MAGENTO_VERSION is now installed and running in container $3. Please browse to http://$MAGENTO_URL"
