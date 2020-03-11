#!/bin/bash

# Load helper functions for configuring kafka server.properties
. properties-helper.sh

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
    set_property advertised.listeners "$KAFKA_ADVERTISED_LISTENERS"
fi

if [ -z "$KAFKA_LISTENERS" ]; then
    echo -e "\e[1;32mERROR - Missing listeners \e[0m"
    exit 1
else
    set_property listeners "$KAFKA_LISTENERS"
fi

if ! [ -z "$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP" ]; then
    set_property listener.security.protocol.map "$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
fi

if ! [ -z "$KAFKA_RETENTION_HOURS" ]; then
    set_property log.retention.hours "$KAFKA_RETENTION_HOURS"
fi

if ! [ -z "$KAFKA_MIN_INSYNC_REPLICAS" ]; then
    set_property min.insync.replicas "$KAFKA_MIN_INSYNC_REPLICAS"
fi

if ! [ -z "$KAFKA_DEFAULT_REPLICATION_FACTOR" ]; then
    set_property default.replication.factor "$KAFKA_DEFAULT_REPLICATION_FACTOR"
fi

if ! [ -z "$KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR" ]; then
    set_property offsets.topic.replication.factor "$KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
fi

if ! [ -z "$KAFKA_INTER_BROKER_LISTENER_NAME" ]; then
    set_property inter.broker.listener.name "$KAFKA_INTER_BROKER_LISTENER_NAME"
fi

# if [[ ! (-z "$KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL") && ! (-z "$KAFKA_INTER_BROKER_LISTENER_NAME") ]]; then
#     echo -e "\e[1;32mERROR - You cannot both set KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL and KAFKA_INTER_BROKER_LISTENER_NAME at the same time! \e[0m"
#     exit 1
# else
# if ! [ -z "$KAFKA_INTER_BROKER_LISTENER_NAME" ]; then
#     set_property inter.broker.listener.name "$KAFKA_INTER_BROKER_LISTENER_NAME"
# fi

# if ! [ -z "$KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL" ]; then
#     set_property security.inter.broker.protocol "$KAFKA_TLS_SECURITY_INTER_BROKER_PROTOCOL"
#     remove_property inter.broker.listener.name
# fi
# fi

if ! [ -z "$KAFKA_TLS_CLIENT_AUTH" ]; then
    set_property ssl.client.auth "$KAFKA_TLS_CLIENT_AUTH"
fi

if ! [ -z "$KAFKA_TLS_SERVER_DNS_HOSTNAME" ]; then
    ssl-setup.sh
fi
