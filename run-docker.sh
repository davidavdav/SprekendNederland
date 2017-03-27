#!/usr/bin/env bash

if [ -z "$PASSWORD" ]; then
    echo "Run as: PASSWORD=password $0"
	exit 1
fi

docker run -p 3306:3306 --name sndb -e MYSQL_ROOT_PASSWORD="$PASSWORD" -d mysql/mysql-server --bind-address=0.0.0.0

## or if the image exists, "docker start sndb"

## mysql -u root -D "" -p
## create database sn;
## grant all privileges on sn.* to 'sn'@'%' identified by 'sn';
