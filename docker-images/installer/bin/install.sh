#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

#####################################
# Update the Magento Installation
# Arguments:
#   None
# Returns:
#   None
#####################################
function updateMagento() {
	cd /var/www/html
	composer update
}

#####################################
# Print URLs and Logon Information
# Arguments:
#   None
# Returns:
#   None
#####################################
function printLogonInformation() {
	baseUrl="http://$DOMAIN"
	frontendUrl="$baseUrl/"
	backendUrl="$baseUrl/admin"

	echo "Frontend: $frontendUrl"
	echo "Backend: $backendUrl"
	echo " - Username: ${ADMIN_USERNAME}"
	echo " - Password: ${ADMIN_PASSWORD}"
}


#####################################
# Fix the filesystem permissions for the magento root.
# Arguments:
#   None
# Returns:
#   None
#####################################
function fixFilesystemPermissions() {
	chmod -R go+rw $MAGENTO_ROOT
}

#####################################
# A never-ending while loop (which keeps the installer container alive)
# Arguments:
#   None
# Returns:
#   None
#####################################
function runForever() {
	while :
	do
		sleep 1
	done
}

#####################################
# Check if mysql service is running
# Arguments:
#   None
# Returns:
#   bool
#####################################
function mysqlIsRunning()
{
    2>/dev/null mysql -u"${MYSQL_USER}" --password="${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -e "exit"
}

#####################################
# Wait until mysql service is running
# Arguments:
#   None
# Returns:
#   0 - waiting for mysql succeeded, 2 - failed up after 10 tries
#####################################
function mysqlWait()
{
    mysql --version
    mysql_tries=1
    while ! mysqlIsRunning; do
        echo "waiting for mysql to become alive (${mysql_tries})..."
        sleep 1
        ((mysql_tries++))
        if [ ${mysql_tries} -gt 10 ]; then
            break;
        fi
    done
    if mysqlIsRunning; then
        echo "Mysql is Reported Up and Running"
        return 0
    else
        echo "Mysql is not running, giving up after ${mysql_tries} attempts"
        return 2
    fi
}

# Check if the MAGENTO_ROOT direcotry has been specified
if [ -z "$MAGENTO_ROOT" ]
then
	echo "Please specify the root directory of Magento via the environment variable: MAGENTO_ROOT"
	exit 1
fi

# Check if the specified MAGENTO_ROOT direcotry exists
if [ ! -d "$MAGENTO_ROOT" ]
then
	mkdir -p $MAGENTO_ROOT
fi

# Check if there is alreay an index.php. If yes, abort the installation process.
if [ -e "$MAGENTO_ROOT/index.php" ]
then
	echo "Magento is already installed."
	echo "Updating Magento"
	updateMagento

	echo "Fixing filesystem permissions"
	fixFilesystemPermissions

	echo "Update fininished"
	printLogonInformation

	runForever
	exit 0
fi

echo "Preparing the Magerun Configuration"
substitute-env-vars.sh /etc /etc/n98-magerun.yaml.tmpl

echo "Starting Installation"
mysqlWait
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" install --noDownload --dbHost="$MYSQL_HOST" --dbUser="$MYSQL_USER" --dbPass="$MYSQL_PASSWORD" --dbName="$MYSQL_DATABASE" --installSampleData="no" --useDefaultConfigParams="yes" --installationFolder="$MAGENTO_ROOT" --baseUrl="http://$DOMAIN"

echo "Installing Magento"
updateMagento

echo "Preparing the Magento Configuration"
substitute-env-vars.sh /etc /etc/local.xml.tmpl
substitute-env-vars.sh /etc /etc/fpc.xml.tmpl

echo "Overriding Magento Configuration"
cp -v /etc/local.xml /var/www/html/web/app/etc/local.xml
cp -v /etc/fpc.xml /var/www/html/web/app/etc/fpc.xml

echo "Installing Sample Data: Reindex"
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" cache:clean
magerun --skip-root-check --root-dir="$MAGENTO_ROOT" index:reindex:all

echo "Fixing filesystem permissions"
fixFilesystemPermissions

echo "Installation fininished"
printLogonInformation

runForever
exit 0
