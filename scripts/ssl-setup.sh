#!/bin/bash
if [[ -f "/ssl/kafka.server.keystore.jks" && -f "/ssl/kafka.server.truststore.jks" ]]; then
    echo "INFO - Keystore and truststore already exists. Using those"
else
    if [ -z "$KAFKA_CERTIFICATE_AUTHORITY_URL" ]; then
        echo -e "\e[1;31mERROR - Missing KAFKA_CERTIFICATE_AUTHORITY_URL \e[0m"
        exit 1
    fi
    # Load helper functions for configuring kafka server.properties
    . properties-helper.sh

    echo "INFO - Configuring SSL"
    export SRVPASS=serversecret

    # Generating a new key. CN refers to hostname. A client compares the CN in the server certificate to the DNS host name in the URL.
    keytool -genkey -keystore /ssl/kafka.server.keystore.jks -alias localhost -validity 365 -dname "CN=$KAFKA_SSL_SERVER_HOSTNAME" -storepass $SRVPASS -keypass $SRVPASS -storetype pkcs12

    # Creating a certification request file, to be signed by the CA
    keytool -keystore /ssl/kafka.server.keystore.jks -alias localhost -certreq -file /ssl/cert-file -storepass $SRVPASS -keypass $SRVPASS

    # Signing the certificate with certificate authorizer
    curl --form certificate-request=@/ssl/cert-file http://"$KAFKA_CERTIFICATE_AUTHORITY_URL"/sign-certificate -o /ssl/cert-signed

    rm /ssl/cert-file

    # Getting the public certificate from certiticate authorizer
    curl http://"$KAFKA_CERTIFICATE_AUTHORITY_URL"/get-certificate -o /ssl/ca-cert

    # Creating a truststore for the kafka broker to trust all clients which the certificate authorithy has signed
    keytool -keystore /ssl/kafka.server.truststore.jks -alias CARoot -import -file /ssl/ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt

    # Import CA and the signed server certificate into the keystore
    keytool -keystore /ssl/kafka.server.keystore.jks -alias CARoot -import -file /ssl/ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt
    keytool -keystore /ssl/kafka.server.keystore.jks -alias localhost -import -file /ssl/cert-signed -storepass $SRVPASS -keypass $SRVPASS -noprompt

    set_property ssl.keystore.location /ssl/kafka.server.keystore.jks
    set_property ssl.keystore.password "$SRVPASS"
    set_property ssl.key.password "$SRVPASS"
    set_property ssl.truststore.location /ssl/kafka.server.truststore.jks
    set_property ssl.truststore.password "$SRVPASS"
fi
