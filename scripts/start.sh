#!/bin/bash

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]
then 
    echo "ERROR Missing essential zookeeper connection URI"
    exit 1
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

echo "INFO Starting Kafka Server"
echo "A LISTERNESR " $KAFKA_ADVERTISED_LISTENERS
echo "LISTENERS " $KAFKA_LISTENERS

/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties \
--override zookeeper.connect="$KAFKA_ZOOKEEPER_CONNECT" \
--override broker.id="$KAFKA_BROKER_ID" \
--override log.dirs="$KAFKA_HOME"/data \
--override advertised.listeners="$KAFKA_ADVERTISED_LISTENERS" \
--override listeners="$KAFKA_LISTENERS" \
--override listener.security.protocol.map="$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP" \
--override inter.broker.listener.name=INSIDE