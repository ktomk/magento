#!/bin/bash
#
# wait-mysql.sh: wait for mysql to become available
#
set -euo pipefail
IFS=$'\n\t'

MYSQL_USER="${MYSQL_USER-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD-}"
MYSQL_HOST="${MYSQL_HOST-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT-3306}" # currently un-used

#####################################
# Check if mysql service is running
# Arguments:
#   None
# Returns:
#   bool
#####################################
function mysqlIsRunning()
{
    mysql -u"${MYSQL_USER}" --password="${MYSQL_PASSWORD}" -h"${MYSQL_HOST}" -e "exit"
}

#####################################
# Wait until mysql service is running
# Arguments:
#   None
# Returns:
#   None
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
    else
        echo "Mysql is not running, giving up after ${mysql_tries} attempts."
    fi
}

mysqlWait
