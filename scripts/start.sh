#!/bin/bash

configure-kafka.sh

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

if ! [ -z "$KAFKA_AUTHENTICATION" ]; then

    if [[ $KAFKA_AUTHENTICATION == KERBEROS ]]; then
        export KAFKA_OPTS="-Djava.security.auth.login.config="$KAFKA_HOME"/config/kerberos_server_jaas.conf -Djava.security.krb5.conf="$KAFKA_HOME"/config/krb5.conf"
    fi
fi

$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
