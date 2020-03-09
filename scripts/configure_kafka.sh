#!/bin/bash

SERVER_PROPERTIES_PATH=$KAFKA_HOME/config/server.properties
# $1 = key $2 = value
function override_property() {
    sed -i "/"$1"=/ s/=.*/="$2"/" $SERVER_PROPERTIES_PATH
}

function set_property() {
    echo -e "\n"$1"=""$2" >> $SERVER_PROPERTIES_PATH
}

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]; then
    echo -e "\e[1;32mERROR - Missing essential zookeeper connection URI \e[0m"
    exit 1
else
    if [[ "$KAFKA_ZOOKEEPER_CONNECT" != *"/kafka"* ]]; then
        echo "INFO - KAFKA_ZOOKEEPER_CONNECT missing chroot suffix, adding default /kafka chroot "
        KAFKA_ZOOKEEPER_CONNECT="$KAFKA_ZOOKEEPER_CONNECT/kafka"
    fi
    set_property zookeeper.connect "$KAFKA_ZOOKEEPER_CONNECT"
fi

if [ -z "$KAFKA_BROKER_ID" ]; then
    echo -e "\e[1;32mERROR - Missing essential BROKER ID \e[0m"
    exit 1
else
    set_property broker.id "$KAFKA_BROKER_ID"
fi

if [ -z "$KAFKA_ADVERTISED_LISTENERS" ]; then
    echo -e "\e[1;32mERROR - Missing advertised listeners \e[0m"
    exit 1
else
    set_property advertised.listeners
fi

if [ -z "$KAFKA_LISTENERS" ]; then
    echo -e "\e[1;32mERROR - Missing listeners \e[0m"
    exit 1
else
    set_property listeners "$KAFKA_LISTENERS"
fi

if ! [ -z "$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP" ]; then
    echo "INFO - Missing listener security protocol map, using default " $KAFKA_LISTENER_SECURITY_PROTOCOL_MAP
fi

if [ -z "$KAFKA_INTER_BROKER_LISTENER_NAME" ]; then
    KAFKA_INTER_BROKER_LISTENER_NAME=INTERNAL
    echo "INFO - Missing inter broker listener name, using default " $KAFKA_INTER_BROKER_LISTENER_NAME
fi

if [ -z "$KAFKA_RETENTION_HOURS" ]; then
    KAFKA_RETENTION_HOURS=168
    echo "INFO - Missing retention hours configuration. Using default of 7 days"
fi

if [ -z "$KAFKA_MIN_INSYNC_REPLICAS" ]; then
    KAFKA_MIN_INSYNC_REPLICAS=1
    echo "INFO - Missing in sync replica configuration. Using default -  1"
fi

if [ -z "$KAFKA_DEFAULT_REPLICATION_FACTOR" ]; then
    KAFKA_DEFAULT_REPLICATION_FACTOR=1
    echo "INFO - Missing default replication factor. Using default -  1"
fi

if [ -z "$KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR" ]; then
    KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
    echo "INFO - Missing default offset replication factor. Using default -  1"
fi

if ! [ -z "$KAFKA_TLS_SERVER_DNS_HOSTNAME" ]; then
    ssl_setup.sh
fi

if [[ ! (-z "$KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL") && ! (-z "$KAFKA_INTER_BROKER_LISTENER_NAME") ]]; then
    echo -e "\e[1;32mERROR - You cannot both set KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL and KAFKA_INTER_BROKER_LISTENER_NAME at the same time! \e[0m"
    exit 1
fi

if [ -z "$KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL" ]; then
    KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL=
    echo "INFO - Missing security_inter_broker_protocol. Using inter_broker_listener_name instead"
else
    KAFKA_INTER_BROKER_LISTENER_NAME=
fi

if [ -z "$KAFKA_TLS_CLIENT_AUTH" ]; then
    KAFKA_TLS_CLIENT_AUTH=none
    echo "INFO - Missing client auth variable. Using default - none"
fi
