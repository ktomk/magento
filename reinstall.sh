#!/bin/bash
#
# reinstall.sh: shut down all images, reset data to trigger magento installation via magerun again
#
set -euo pipefail
IFS=$'\n\t'

sudo docker-compose stop
sudo rm -rf web vendor data/mysql
composer install
rm web/index.php

docker_image_eradicate()
{
    local image="${1}"

    local images="$(sudo docker ps -qa -f ancestor=${image})"

    if [ "x${images}" != "x" ]; then
        sudo docker rm ${images}
    fi
    sudo docker rmi "${image}"
}

docker_image_eradicate btammdebug_installer
