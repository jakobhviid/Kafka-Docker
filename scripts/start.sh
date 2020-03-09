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

# TODO - find a better way to set server.properties (besides sed bash command)
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
    --override offsets.topic.replication.factor="$KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR" \
    --override ssl.client.auth="$KAFKA_TLS_CLIENT_AUTH"
--override security.inter.broker.protocol="$KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL"
