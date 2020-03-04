#!/bin/bash

# scp -r root@"$KERBEROS_SERVER_IP":"$KERBEROS_KEYTAB_LOCATION" /keytabs/kafka.service.keytab

sed -i 's/principal=.*$/principal="$KERBEROS_PRINCIPAL"/' ${KAFKA_HOME}/config/kafka_server_jaas.conf

export KAFKA_OPTS="-Djava.security.auth.login.config="$KAFKA_HOME"/config/kafka_server_jaas.conf"
