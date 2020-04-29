#!/bin/bash

# Load helper functions for configuring kafka server.properties
. properties-helper.sh

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]; then
    echo -e "\e[1;32mERROR - Missing essential zookeeper connection URI \e[0m"
    exit 1
else
    if [[ "$KAFKA_ZOOKEEPER_CONNECT" != *"/kafka"* ]]; then
        echo "INFO - KAFKA_ZOOKEEPER_CONNECT missing chroot suffix, adding default /kafka chroot "
        set_property zookeeper.connect "$KAFKA_ZOOKEEPER_CONNECT"/kafka
    else
        set_property zookeeper.connect "$KAFKA_ZOOKEEPER_CONNECT"
    fi
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
    # adding a healthcheck port (55555)
    set_property advertised.listeners "$KAFKA_ADVERTISED_LISTENERS",HEALTHCHECK://localhost:55555
fi

if [ -z "$KAFKA_LISTENERS" ]; then
    echo -e "\e[1;32mERROR - Missing listeners \e[0m"
    exit 1
else
    # adding a healthcheck port (55555)
    set_property listeners "$KAFKA_LISTENERS",HEALTHCHECK://0.0.0.0:55555
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

if ! [ -z "$KAFKA_INTER_BROKER_LISTENER_NAME" ]; then
    set_property inter.broker.listener.name "$KAFKA_INTER_BROKER_LISTENER_NAME"
fi

# If this is set it means that kafka should be ssl encrypted. Therefor run ssl-setup.sh
if ! [ -z "$KAFKA_SSL_SERVER_HOSTNAME" ]; then
    ssl-setup.sh
fi

# If this is set it means some authentication should be enabled. Currently only Kerberos is supported, but this can be extended if needed to OAUTHBEARER, 2-WAY SSL etc.
if ! [ -z ${KAFKA_AUTHENTICATION} ]; then
    shopt -s nocasematch # ignore case of 'kerberos'
    if [[ ${KAFKA_AUTHENTICATION} == KERBEROS ]]; then

        # test if a keytab has been provided and if it's in the expected directory
        kafka_keytab_location=/sasl/kafka.service.keytab
        if ! [[ -f "${kafka_keytab_location}" ]]; then
            echo -e "\e[1;32mERROR - Missing kafka kerberos keytab file '"$kafka_keytab_location"'. This is required to enable kerberos. Provide it with a docker volume or docker mount \e[0m"
            exit 1
        fi

        if [[ -z "${KAFKA_KERBEROS_PRINCIPAL}" ]]; then
            echo -e "\e[1;32mERROR - Missing 'KAFKA_KERBEROS_PRINCIPAL' environment variable. This is required to enable kerberos \e[0m"
            exit 1
        else
            set_principal_in_jaas_file "$KAFKA_HOME"/config/kerberos_server_jaas.conf "$KAFKA_KERBEROS_PRINCIPAL"
        fi

        if [[ -z "${KERBEROS_PUBLIC_URL}" ]]; then
            echo -e "\e[1;32mERROR - Missing 'KERBEROS_PUBLIC_URL' environment variable. This is required to enable kerberos \e[0m"
            exit 1
        fi

        if [[ -z "${KERBEROS_REALM}" ]]; then
            echo -e "\e[1;32mERROR - Missing 'KERBEROS_REALM' environment variable. This is required to enable kerberos \e[0m"
            exit 1
        fi

        if [[ -z "${ZOOKEEPER_KERBEROS_PRINCIPAL}" ]]; then
            echo -e "\e[1;32mERROR - Missing 'ZOOKEEPER_KERBEROS_PRINCIPAL' environment variable. This is required to enable kerberos communication with zookeeper! \e[0m"
        else
            # test if a zookeeper keytab has been provided and if it's in the expected directory
            zookeeper_keytab_location=/sasl/zookeeper.service.keytab
            if ! [[ -f "${zookeeper_keytab_location}" ]]; then
                echo -e "\e[1;32mERROR - Missing zookeeper kerberos keytab file '"$zookeeper_keytab_location"'. This is required to enable kerberos authentication with zookeeper. Provide it with a docker volume or docker mount \e[0m"
                exit 1
            fi
            echo "INFO - 'ZOOKEEPER_KERBEROS_PRINCIPAL' is set, and a zookeeper keytab has been provided! Kafka will connect to zookeeper with kerberos "

            # Deleting previous client configuration if already specified
            client_line=$(awk '/Client/{ print NR; exit }' $KAFKA_HOME/config/kerberos_server_jaas.conf
            if  ! [[ -z "$client_line" ]]; then
                sed -i "'"$client_line"',$d" $KAFKA_HOME/config/kerberos_server_jaas.conf
            fi
            
            printf "\nClient {\n\tcom.sun.security.auth.module.Krb5LoginModule required\n\tuseKeyTab=true\n\tstoreKey=true\n\tkeyTab=\""$zookeeper_keytab_location"\"\n\tprincipal=\""${ZOOKEEPER_KERBEROS_PRINCIPAL}"\";\n};\n" >>$KAFKA_HOME/config/kerberos_server_jaas.conf
        fi

        # server configuration
        set_property sasl.enabled.mechanisms GSSAPI
        set_property sasl.kerberos.service.name kafka

        configure_kerberos_server_in_krb5_file "$KERBEROS_REALM" "$KERBEROS_PUBLIC_URL"
    fi
fi

if ! [ -z "$KAFKA_ACL_ENABLE" ]; then
    if ! [ -z "$KAFKA_ACL_SUPER_USERS" ]; then
        set_property super.users "$KAFKA_ACL_SUPER_USERS"
    fi

    if ! [ -z "$KAFKA_ZOOKEEPER_SET_ACL" ]; then
        set_property zookeeper.set.acl true
    fi
    
    set_property authorizer.class.name kafka.security.auth.SimpleAclAuthorizer
    set_property allow.everyone.if.no.acl.found false
fi
