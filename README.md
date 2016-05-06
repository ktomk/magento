
## Dockerized Magento Enterprise 1.14.2.4 Preparations

The web-server will be bound to your local ports 80 and 443. In order to access the shop you must add a hosts file entry for `magento.dev`.

### For Mac Users

# Prepare VM dependencies
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install docker docker-machine docker-compose docker-machine-nfs && docker -v && docker-machine -v && docker-compose -v && brew cleanup

# Setup Dev Environment
docker-machine create --virtualbox-memory "4096" --virtualbox-disk-size "20000" --virtualbox-cpu-count "2" --driver virtualbox dev
eval "$(docker-machine env dev)"
docker-machine-nfs dev -n="-alldirs -maproot=0"

# Clone Repository
cd /users/btamm/sites && git clone git@github.com:brandontamm/magento.git && cd magento

# Build Dev Environment
docker-compose up

# Add Domain Name to OSX Localhost
sudo sh -c "echo 192.168.99.100 magento.dev >> /etc/hosts"

## Usage

You can control the project using the built-in `magento`-script which is basically just a **wrapper for docker and docker-compose** that offers some **convenience features**:

```bash
./magento <action>
```

**Available Actons**

- **start**: Starts the docker containers (and triggers the installation if magento is not yet installed)
- **stop**: Stops all docker containers
- **restart**: Restarts all docker containers and flushes the cache
- **status**: Prints the status of all docker containers
- **stats**: Displays live resource usage statistics of all containers
- **magerun**: Executes magerun in the magento root directory
- **composer**: Executes composer in the magento root directory
- **enter**: Enters the bash of a given container type (e.g. php, mysql, ...)
- **destroy**: Stops all containers and removes all data

**Note**: The `magento`-script is just a small wrapper around `docker-compose`. You can just use [docker-compose](https://docs.docker.com/compose/) directly.

## Components

### Overview

The dockerized Magento project consists of the following components:

- **[docker images](docker-images)**
  1. a [php 5.5](docker-images/php/5.5/Dockerfile) image
  2. a [nginx](docker-images/nginx/Dockerfile) web server image
  3. a [solr](docker-images/solr/Dockerfile) search server
  4. a standard [mysql](https://registry.hub.docker.com/_/mysql/) database server image
  5. multiple instances of the standard [redis](https://registry.hub.docker.com/_/redis/) docker image
  6. and an [installer](docker-images/installer/Dockerfile) image which contains all tools for installing the project from scratch using an [install script](docker-images/installer/bin/install.sh)
- a **[shell script](magento)** for controlling the project: [`./magento <action>`](magento)
- a [composer-file](composer.json) for managing the **Magento modules**
- and the [docker-compose.yml](docker-compose.yml)-file which connects all components
