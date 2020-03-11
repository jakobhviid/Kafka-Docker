```
export CLIPASS=clientpass

# Get the certificate from the CA
curl http://localhost:5000/get-certificate -o ./ca-cert

# create truststore (which certificates to trust)
keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ca-cert  -storepass $CLIPASS -keypass $CLIPASS -noprompt

# See the contents
keytool -list -v -keystore kafka.client.truststore.jks

# create keystore (your own identity), remember to replace <<laptop_host_name>>
keytool -genkey -keystore kafka.client.keystore.jks -validity 365 -storepass $CLIPASS -keypass $CLIPASS  -dname "CN=<<laptop_host_name>>" -alias kafka_client -storetype pkcs12

# Create certifcation request file
keytool -keystore kafka.client.keystore.jks -certreq -file cert-sign-request -alias kafka_client -storepass $CLIPASS -keypass $CLIPASS

# Sign the request
curl --form certificate-request=@./cert-sign-request http://<<certificate_authority_dns>>:<<certificate_authorithy_port>>/sign-certificate -o ./cert-signed

# Import root certificate into keystore
keytool -keystore kafka.client.keystore.jks -alias CARoot -import -file ca-cert -storepass $CLIPASS -keypass $CLIPASS -noprompt
# Import signed certificate into keystore
keytool -keystore kafka.client.keystore.jks -import -file cert-signed -alias kafka_client -storepass $CLIPASS -keypass $CLIPASS -noprompt

# Make a client-ssl.properties file, remember to replace <<path>>

security.protocol=SSL
ssl.truststore.location=<<path>>/kafka.client.truststore.jks
ssl.truststore.password=clientpass
ssl.keystore.location=<<path>>/kafka.client.keystore.jks
ssl.keystore.password=clientpass
ssl.key.password=clientpass

/kafka/bin/kafka-console-producer.sh --broker-list <<kafka_server_dns>> --topic kafka-test-ssl-topic --producer.config ./client-ssl.properties
```