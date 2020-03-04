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
    KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
    echo "INFO Missing listener security protocol map, using default " $KAFKA_LISTENER_SECURITY_PROTOCOL_MAP
fi

if [ -z "$KAFKA_INTER_BROKER_LISTENER_NAME" ]
then 
    KAFKA_INTER_BROKER_LISTENER_NAME=INTERNAL
    echo "INFO Missing inter broker listener name, using default " $KAFKA_INTER_BROKER_LISTENER_NAME
fi

if [ -z "$KAFKA_RETENTION_HOURS" ]
then
    KAFKA_RETENTION_HOURS=168
    echo "INFO Missing retention hours configuration. Using default of 7 days"
fi

if [ -z "$KAFKA_MIN_INSYNC_REPLICAS" ]
then
    KAFKA_MIN_INSYNC_REPLICAS=1
    echo "INFO Missing in sync replica configuration. Using default -  1"
fi

if [ -z "$KAFKA_DEFAULT_REPLICATION_FACTOR" ]
then
    KAFKA_DEFAULT_REPLICATION_FACTOR=1
    echo "INFO Missing default replication factor. Using default -  1"
fi

if [ -z "$KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR" ]
then
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
    echo "INFO Missing default offset replication factor. Using default -  1"
fi

echo "INFO Configuring Kafka Server"

# File descript limits
echo "* hard nofile 100000
* soft nofile 100000" | tee --append /etc/security/limits.conf

# avoid swapping
sysctl vm.swappiness=0

echo "INFO Starting Kafka Server"

/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties \
--override zookeeper.connect="$KAFKA_ZOOKEEPER_CONNECT" \
--override broker.id="$KAFKA_BROKER_ID" \
--override advertised.listeners="$KAFKA_ADVERTISED_LISTENERS" \
--override listeners="$KAFKA_LISTENERS" \
--override listener.security.protocol.map="$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP" \
--override inter.broker.listener.name="$KAFKA_INTER_BROKER_LISTENER_NAME" \
--override log.retention.hours="$KAFKA_RETENTION_HOURS" \
--override min.insync.replicas="$KAFKA_MIN_INSYNC_REPLICAS" \
--override default.replication.factor="$KAFKA_DEFAULT_REPLICATION_FACTOR" \
--override offsets.topic.replication.factor="$KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"