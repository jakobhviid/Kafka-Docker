#!/bin/bash

configure_kafka.sh

if [ $? != 0 ]; then
    exit 1
fi

# File descript limits
echo "* hard nofile 100000
* soft nofile 100000" | tee --append /etc/security/limits.conf

# avoid RAM swapping
sysctl vm.swappiness=1

echo "INFO - Starting Kafka Server"

cat $KAFKA_HOME/config/server.properties
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
