#!/bin/bash

# Load helper functions for configuring kafka server.properties
. properties-helper.sh

if [ -z "$KAFKA_ZOOKEEPER_CONNECT" ]; then
    echo -e "\e[1;31mERROR - Missing essential zookeeper connection URI \e[0m"
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
    echo -e "\e[1;31mERROR - Missing essential 'KAFKA_BROKER_ID' \e[0m"
    exit 1
else
    set_property broker.id "$KAFKA_BROKER_ID"
fi

if [ -z "$KAFKA_ADVERTISED_LISTENERS" ]; then
    echo -e "\e[1;31mERROR - Missing 'KAFKA_ADVERTISED_LISTENERS' \e[0m"
    exit 1
else
    # adding a healthcheck port (55555)
    set_property advertised.listeners "$KAFKA_ADVERTISED_LISTENERS",HEALTHCHECK://localhost:55555
fi

if [ -z "$KAFKA_LISTENERS" ]; then
    echo -e "\e[1;31mERROR - Missing 'KAFKA_LISTENERS' \e[0m"
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

        if [[ -z "${KAFKA_KERBEROS_PUBLIC_URL}" ]]; then
            echo -e "\e[1;31mERROR - Missing 'KAFKA_KERBEROS_PUBLIC_URL' environment variable. This is required to enable kerberos \e[0m"
            exit 1
        fi

        if [[ -z "${KAFKA_KERBEROS_REALM}" ]]; then
            echo -e "\e[1;31mERROR - Missing 'KAFKA_KERBEROS_REALM' environment variable. This is required to enable kerberos \e[0m"
            exit 1
        fi

        kafka_keytab_location=/sasl/kafka.service.keytab
        # If they haven't provided their own keytabs in volumes, it is tested if they have provided the necessary environment variables to download the keytab from an API
        if [[ -z "${KAFKA_KERBEROS_PRINCIPAL}" ]]; then
            if [[ -z "${KAFKA_KERBEROS_API_URL}" ]]; then
                echo -e "\e[1;31mERROR - One of either 'KAFKA_KERBEROS_PRINCIPAL' or 'KAFKA_KERBEROS_API_URL' must be supplied! It is required to enable kerberos for kafka! \e[0m"
                exit 1
            else # the user wants to use a kerberos api to get keytabs

                # Test for all the required environment variables
                if [[ -z "${KAFKA_KERBEROS_API_KAFKA_USERNAME}" ]]; then
                    echo -e "\e[1;31mERROR - Missing 'KAFKA_KERBEROS_API_KAFKA_USERNAME' environment variable. This is required to use kerberos API for kafka keytab \e[0m"
                    exit 1
                fi
                if [[ -z "${KAFKA_KERBEROS_API_KAFKA_PASSWORD}" ]]; then
                    echo -e "\e[1;31mERROR - Missing 'KAFKA_KERBEROS_API_KAFKA_PASSWORD' environment variable. This is required to use kerberos API for kafka keytab \e[0m"
                    exit 1
                fi

                export KAFKA_KERBEROS_PRINCIPAL="$KAFKA_KERBEROS_API_KAFKA_USERNAME"@"$KAFKA_KERBEROS_REALM"
                # response will be 'FAIL' if it can't connect or if the url returned an error
                response=$(curl --fail --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 30 --retry-connrefused --max-time 5 -X POST -H "Content-Type: application/json" -d "{\"username\":\""$KAFKA_KERBEROS_API_KAFKA_USERNAME"\", \"password\":\""$KAFKA_KERBEROS_API_KAFKA_PASSWORD"\"}" "$KAFKA_KERBEROS_API_URL" -o "$kafka_keytab_location" && echo "INFO - Using the keytab from the API and a principal name of '"$KAFKA_KERBEROS_API_KAFKA_USERNAME"'@'"$KAFKA_KERBEROS_REALM"'" || echo "FAIL")
                if [ "$response" == "FAIL" ]; then
                    echo -e "\e[1;31mERROR - Kerberos API did not succeed when fetching kafka keytab. Retrying in 5 seconds \e[0m"
                    sleep 5

                    # retrying
                    response=$(curl --fail --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 30 --retry-connrefused --max-time 5 -X POST -H "Content-Type: application/json" -d "{\"username\":\""$KAFKA_KERBEROS_API_KAFKA_USERNAME"\", \"password\":\""$KAFKA_KERBEROS_API_KAFKA_PASSWORD"\"}" "$KAFKA_KERBEROS_API_URL" -o "$kafka_keytab_location" && echo "INFO - Using the keytab from the API and a principal name of '"$KAFKA_KERBEROS_API_KAFKA_USERNAME"'@'"$KAFKA_KERBEROS_REALM"'" || echo "FAIL")
                    if [ "$response" == "FAIL" ]; then
                        echo -e "\e[1;31mERROR - Kerberos API did not succeed when fetching kafka keytab. See curl error above for further details. Exiting \e[0m"
                        exit 1
                    else
                        echo "INFO - Successfully communicated with kerberos and logged in"
                    fi
                else
                    echo "INFO - Successfully communicated with kerberos and logged in"
                fi
            fi
        else # The user has supplied their own principals

            # test if a keytab has been provided and if it's in the expected directory
            if ! [[ -f "${kafka_keytab_location}" ]]; then
                echo -e "\e[1;31mERROR - Missing kafka kerberos keytab file '"$kafka_keytab_location"'. This is required to enable kerberos when 'KAFKA_KERBEROS_PRINCIPAL' is supplied. Provide it with a docker volume or docker mount \e[0m"
                exit 1
            else
                echo "INFO - Using the supplied keytab and the principal from environment variable 'KAFKA_KERBEROS_PRINCIPAL' "
            fi
        fi
        # Setting the principal which will either be from the environment variable or the export if the kerberos API is to be used
        set_principal_in_jaas_file "$KAFKA_HOME"/config/kerberos_server_jaas.conf "$KAFKA_KERBEROS_PRINCIPAL"

        zookeeper_keytab_location=/sasl/zookeeper.service.keytab
        # If they haven't provided their own keytabs in volumes, it is tested if they have provided the necessary environment variables to download the keytab from an API
        if [[ -z "${KAFKA_ZOOKEEPER_KERBEROS_PRINCIPAL}" ]]; then
            if [[ -z "${KAFKA_KERBEROS_API_URL}" ]]; then
                echo -e "\e[1;31mERROR - One of either 'KAFKA_ZOOKEEPER_KERBEROS_PRINCIPAL' or 'KAFKA_KERBEROS_API_URL' must be supplied! It is required to enable kerberos for zookeeper! \e[0m"
                exit 1
            else # User wants to use the kerberos API
                if [[ -z "${KAFKA_KERBEROS_API_ZOOKEEPER_USERNAME}" ]]; then
                    echo -e "\e[1;31mERROR - Missing 'KAFKA_KERBEROS_API_ZOOKEEPER_USERNAME' environment variable. This is required to use kerberos API for zookeeper keytab \e[0m"
                    exit 1
                fi
                if [[ -z "${KAFKA_KERBEROS_API_ZOOKEEPER_PASSWORD}" ]]; then
                    echo -e "\e[1;31mERROR - Missing 'KAFKA_KERBEROS_API_ZOOKEEPER_PASSWORD' environment variable. This is required to use kerberos API for zookeeper keytab \e[0m"
                    exit 1
                fi

                export KAFKA_ZOOKEEPER_KERBEROS_PRINCIPAL="$KAFKA_KERBEROS_API_ZOOKEEPER_USERNAME"@"$KAFKA_KERBEROS_REALM"

                # response will be 'FAIL' if it can't connect or if the url returned an error
                response=$(curl --fail --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 30 --retry-connrefused --max-time 5 -X POST -H "Content-Type: application/json" -d " {\"username\":\""$KAFKA_KERBEROS_API_ZOOKEEPER_USERNAME"\", \"password\":\""$KAFKA_KERBEROS_API_ZOOKEEPER_PASSWORD"\"}" "$KAFKA_KERBEROS_API_URL" -o "$zookeeper_keytab_location" && echo "INFO - Using the keytab from the API and a principal name of '"$KAFKA_KERBEROS_API_ZOOKEEPER_USERNAME"'@'"$KAFKA_KERBEROS_REALM"'" || echo "FAIL")
                if [ "$response" == "FAIL" ]; then
                    echo -e "\e[1;31mERROR - Kerberos API did not succeed when fetching zookeeper keytab. Retrying in 5 seconds \e[0m"
                    sleep 5

                    # retrying
                    response=$(curl --fail --connect-timeout 5 --retry 5 --retry-delay 5 --retry-max-time 30 --retry-connrefused --max-time 5 -X POST -H "Content-Type: application/json" -d " {\"username\":\""$KAFKA_KERBEROS_API_ZOOKEEPER_USERNAME"\", \"password\":\""$KAFKA_KERBEROS_API_ZOOKEEPER_PASSWORD"\"}" "$KAFKA_KERBEROS_API_URL" -o "$zookeeper_keytab_location" && echo "INFO - Using the keytab from the API and a principal name of '"$KAFKA_KERBEROS_API_ZOOKEEPER_USERNAME"'@'"$KAFKA_KERBEROS_REALM"'" || echo "FAIL")
                    if [ "$response" == "FAIL" ]; then
                        echo -e "\e[1;31mERROR - Kerberos API did not succeed when fetching zookeeper keytab. See curl error above for further details. Exiting \e[0m"
                        exit 1
                    else
                        echo "INFO - Successfully communicated with kerberos and logged in"
                    fi
                else
                    echo "INFO - Successfully communicated with kerberos and logged in"
                fi
            fi
        else # the user has supplied their own zookeeper keytab
            # test if it's in the expected directory
            if ! [[ -f "${zookeeper_keytab_location}" ]]; then
                echo -e "\e[1;31mERROR - Missing zookeeper kerberos keytab file '"$zookeeper_keytab_location"'. This is required to enable kerberos authentication with zookeeper when 'KAFKA_ZOOKEEPER_KERBEROS_PRINCIPAL' is provided. Provide it with a docker volume or docker mount \e[0m"
                exit 1
            else
                echo "INFO - Using the supplied keytab and the principal from environment variable 'ZOOKEEPER_KERBEROS_PRINCIPAL' "
            fi
        fi

        if ! [[ -z "${KAFKA_ZOOKEEPER_KERBEROS_PRINCIPAL}" ]]; then
            # Deleting previous client configuration if already specified
            client_line=$(awk '/Client/{ print NR; exit }' $KAFKA_HOME/config/kerberos_server_jaas.conf)
            if ! [[ -z "$client_line" ]]; then
                sed -i ''"$client_line"',$d' $KAFKA_HOME/config/kerberos_server_jaas.conf
            fi

            printf "\nClient {\n\tcom.sun.security.auth.module.Krb5LoginModule required\n\tuseKeyTab=true\n\tstoreKey=true\n\tkeyTab=\""$zookeeper_keytab_location"\"\n\tprincipal=\""${KAFKA_ZOOKEEPER_KERBEROS_PRINCIPAL}"\";\n};\n" >>$KAFKA_HOME/config/kerberos_server_jaas.conf
        fi

        # server configuration
        set_property sasl.enabled.mechanisms GSSAPI
        set_property sasl.kerberos.service.name kafka

        configure_kerberos_server_in_krb5_file "$KAFKA_KERBEROS_REALM" "$KAFKA_KERBEROS_PUBLIC_URL"
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

if ! [[ -z "$KAFKA_AUTHORIZATION_DEBUG" ]]; then
    sed -i "/log4j.logger.kafka.authorizer.logger=/ s/=.*/=DEBUG, authorizerAppender /" "$KAFKA_HOME"/config/log4j.properties
fi
