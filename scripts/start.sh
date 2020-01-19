#!/bin/bash

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]
then 
    echo "ERROR Missing essential zookeeper connection URI"
    exit 1
else
    if [[ "$KAFKA_ZOOKEEPER_CONNECT" != *"/kafka"* ]]
    then
        echo "INFO KAFKA_ZOOKEEPER_CONNECT missing chroot suffix, adding default /kafka chroot"
        KAFKA_ZOOKEEPER_CONNECT="$KAFKA_ZOOKEEPER_CONNECT/kafka"
    fi
fi

if [ -z "$KAFKA_BROKER_ID" ]
then 
    echo "ERROR Missing essential BROKER ID"
    exit 1
fi

if [ -z "$KAFKA_ADVERTISED_LISTENERS" ]
then 
    echo "ERROR Missing advertised listeners"
    exit 1
fi

if [ -z "$KAFKA_LISTENERS" ]
then 
    echo "ERROR Missing listeners"
    exit 1
fi

if [ -z "$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP" ]
then 
    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=INSIDE:PLAINTEXT,OUTSIDE:PLAINTEXT
    echo "INFO Missing listener security protocol map, using default " $KAFKA_LISTENER_SECURITY_PROTOCOL_MAP
fi

if [ -z "$KAFKA_RETENTION_HOURS" ]
then
    KAFKA_RETENTION_HOURS=168
    echo "INFO Missing retention hours configuration. Using default of 7 days " $KAFKA_RETENTION_HOURS
fi

echo "INFO Configuring Kafka Server"

echo "* hard nofile 100000
* soft nofile 100000" | tee --append /etc/security/limits.conf

echo "INFO Starting Kafka Server"

/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties \
--override zookeeper.connect="$KAFKA_ZOOKEEPER_CONNECT" \
--override broker.id="$KAFKA_BROKER_ID" \
--override advertised.listeners="$KAFKA_ADVERTISED_LISTENERS" \
--override listeners="$KAFKA_LISTENERS" \
--override listener.security.protocol.map="$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP" \
--override log.retention.hours="$KAFKA_RETENTION_HOURS"