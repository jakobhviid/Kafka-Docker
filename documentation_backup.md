# <a name="how-to-use"></a> How To Use

**NOTE:** Kafka requires at least one running zookeeper node in order to work. 
<a href="https://hub.docker.com/repository/docker/cfei/zookeeper" target="_blank">Zookeeper Image</a>

The following docker-compose file have been provided to demonstrate deployment of a single Kafka broker without ssl. Replace `<<some_configuration>>` for your setup. 

It's necessary to open ports on the host machine for outside connections. In this example Kafka will listen on 9092 (broker-broker connections) & 9093 (client connections) as these are the ports defined in `KAFKA_LISTENERS` and `KAFKA_ADVERTISED_LISTENERS`.

```
version: "3"

services:
  kafka1:
    image: cfei/kafka
    container_name: kafka
    restart: always
    ports:
      - "9092:9092"
      - "9093:9093"
    volumes:
      - ./data:/data/kafka
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: <<zookeeper1_ip>>:2181,<<zookeeper2_ip>>:2181,<<zookeeper3_ip>>:2181
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://<<server_ip>>:9093,EXTERNAL://<<server_ip>>:9092
      KAFKA_LISTENERS: INTERNAL://0.0.0.0:9093,EXTERNAL://0.0.0.0:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 2
      KAFKA_MIN_INSYNC_REPLICAS: 2
      KAFKA_RETENTION_HOURS: 336
      KAFKA_HEAP_OPTS: "-Xmx8G -Xms4G"
```

# Configuration

**Configurations for a basic setup**

- `KAFKA_BROKER_ID`: A unique and permanent number, naming the node in the cluster. This has to be unique for each Kafka container. Required.

- `KAFKA_ZOOKEEPER_CONNECT`: Comma-separated list of Zookeeper URIs' which Kafka will connect to. Kafka will connect to the first available zookeeper. If that goes down it will go to the next and connect to it. Required.

- `KAFKA_ADVERTISED_LISTENERS`: Advertised listeners for clients to use. This value is given to zookeeper so that clients and other Kafka nodes can discover Kafka brokers through Zookeeper. At least two advertised listeners should be configured separated by a comma. In the example given in [How To Use](#how-to-use) two listeners are configured, one listener for broker to broker communication (INTERNAL) and one listener for clients (EXTERNAL). **Note**: Do not configure a listener with port 55555, this is reserved for internal use in the container and do not expose this port to the host network! Required.

- `KAFKA_LISTENERS`: Comma-separated list of URIs' on which Kafka will listen. Wildcard IP-address are allowed.  At least two listeners should be configured separated by a comma. In the example given in [How To Use](#how-to-use) two listeners are configured, one listener for broker to broker communication (INTERNAL) and one listener for clients (EXTERNAL). **Note**: Do not configure a listener with port 55555, this is reserved for internal use in the container and do not expose this port to the host network! Required.

- `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR`: Replication factor for the essential topic 'consumer_offsets'. Should have a value of at least 2 to ensure availability. Default is 1 and is not ideal.

**Other configurations**

- `KAFKA_MIN_INSYNC_REPLICAS`: Minimum number of replicas (brokers) that must acknowledge writes. Enforces greater durability and should at least be 2. Default is 1 for single broker deployments.

- `KAFKA_RETENTION_HOURS`: Number of hours to keep a log file before deleting it. The higher retention hours the longer data will stay in Kafka. Default is 168 hours (7 days).

- `KAFKA_LISTENER_SECURITY_PROTOCOL_MAP`: A mapping between listener names and security protocols. Required when brokers is set up with SSL. Default is INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT,INTERNAL_SSL:SSL,EXTERNAL_SSL:SSL,SSL:SSL,PLAINTEXT:PLAINTEXT.

- `KAFKA_INTER_BROKER_LISTENER_NAME`: The name of the listener used for broker-broker communication. Default is 'INTERNAL'.

- `KAFKA_DEFAULT_REPLICATION_FACTOR`: If a topic isn't created explicitly and therefore created automatically, the default replication factor will be used. Default is 1.

- `KAFKA_HEAP_OPTS`: Configuring Heap size for Kafka, Xmx = max heap size and Xms = initial heap size. Default is "-Xmx256M". 

- `KAFKA_JVM_PERFORMANCE_OPTS`: Configuring JVM options for Kafka. Default is ""-server -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:+ExplicitGCInvokesConcurrent -Djava.awt.headless=true""

- `KAFKA_SSL_SERVER_HOSTNAME`: When you want to configure SSL for Kafka this is required. It will automate creation of keystore and truststore for the Kafka broker. In order to do this it needs to know the DNS resolvable name of the server on which the container is running for proper FQDN (Fully Qualified Common Name lookup). **Important**: This cannot be an IP-address. It has to be DNS resolvable! It should be the URL which clients will use to connect to Kafka. For further details see [SSL](#ssl). Required for SSL setup.

- `KAFKA_CLIENT_AUTH`: Used when you want to enable ACL's  (Access Control List) between client and Kafka cluster. By default it's set to None, so Kafka will not validate clients identity, it can be set to either `Required` or `Requested`, it is recommended to set to `Required`, which makes Kafka validate clients identity every time. `Requested` means clients can choose if they want to be have their identity validated, this is not secure.

- `KAFKA_CERTIFICATE_AUTHORITY_URL`: URL of the certificate authority to be used. This is meant for cfei/certificate_authority use. If you want to use your own certificate. See [volumes](#volumes) /ssl/.

- `KAFKA_AUTHENTICATION`: Authentication schema to use. Currently only Kerberos is supported. Set to 'KERBEROS' for a kerberus setup. Required for [Kerberos setup](#kerberos).

- `KERBEROS_PUBLIC_URL`: Public DNS of the kerberos server to use. Required for [Kerberos setup](#kerberos).

- `KERBEROS_PRINCIPAL`: The principal that kafka should use from the kerberos server. Required for [Kerberos setup](#kerberos).

- `KERBEROS_REALM`: The realm to use on the kerberos server. Required for [Kerberos setup](#kerberos).

- `KAFKA_KERBEROS_PRINCIPAL`: The realm to use from the kerberos server for kafka. Required for [Kerberos setup](#kerberos).

- `ZOOKEEPER_KERBEROS_PRINCIPAL`: If zookeeper is configured to use kerberos, the principal to use to connect to zookeeper is provided with this environment variable. Required for Kerberos connection to zookeeper.

- `KAFKA_ACL_ENABLE`: This will enable kafka.security.auth.SimpleAclAuthorizer. Required for [ACL setup[(#acl).

- `KAFKA_ACL_SUPER_USERS`: If ACL has been set, it's possible to configure super users. These users will have access to all topics and all operations on these topics.

# <a name="volumes"></a> Volumes

- `/data/kafka`: The directory where Kafka checkpoint data is saved. This is important for container recreation.
- `/opt/kafka/logs`: The directory where Kafka stores logs, useful for debugging purposes but not important for container recreation.
- `/ssl/`: The directory where the keystore and truststore for SSL setup is stored, this can be mounted if you want to provide your own keystores and truststores which stops the container from making it's own stores.
- `/sasl/kafka.service.keytab`: The kerberos keytab kafka should use when configured with kerberos. Required for [Kerberos setup](#kerberos).

# <a name="security"></a> Security

## <a name="ssl"></a> SSL/TLS

### docker-compose SSL setup example

The following docker-compose example has enabled SSL both between brokers (broker to broker communication) and to outside connections (clients). If broker to broker communication is on a closed network it is not necessary to use SSL as there is some performance overhead.

 ```
version: "3"

services:
  kafka:
    image: cfei/kafka
    ports:
      - 9092:9092
      - 9093:9093
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: <<zookeeper1_ip>>:2181,<<zookeeper2_ip>>:2181,<<zookeeper3_ip>>:2181
      KAFKA_INTER_BROKER_LISTENER_NAME: SSL
      KAFKA_LISTENERS: SSL://0.0.0.0:9092,EXTERNAL_SSL://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: SSL://<<server_ip>>:9092,EXTERNAL_SSL://<<server_ip>>:9093
      KAFKA_TLS_SERVER_DNS_HOSTNAME: <<server_FQDN>>
      KAFKA_CERTIFICATE_AUTHORITY_URL: ca:5000
    depends_on:
      - ca
  ca:
    image: cfei/certificate_authority
    volumes:
      - ./cert-auth:/ssl/ 
```

## <a name="authentication"></a> Authentication

### <a name="kerberos"></a> Kerberos
#### docker-compose kafka kerberos example

This is a Kerberos setup where zookeeper is on a private network and therefore does not use kerberos. See next example for kafka kerberos authentication with a zookeeper kerberos server.

This docker-compose example does not use SSL. If you want to use SSL, replace 'INTERNAL', with' INTERNAL_SSL' and set 'KAFKA_INTER_BROKER_LISTENER_NAME' to 'INTERNAL_SSL' (only if broker-broker communication is on a public network). You also need to set 'SASL_PLAINTEXT' to 'SASL_SSL'. 

The kafka broker requires a provided keytab in /sasl/kafka.service.keytab

```
version: "3"

services:
  kafka:
    image: cfei/kafka
    ports:
      - 9092:9092
      - 9093:9093
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: <<zookeeper1_ip>>:2181,<<zookeeper2_ip>>:2181,<<zookeeper3_ip>>:2181
      KAFKA_LISTENERS: INTERNAL://0.0.0.0:9092,SASL_PLAINTEXT://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://<<server_ip>>:9092,SASL_PLAINTEXT://<<server_ip>>:9093
      KAFKA_AUTHENTICATION: KERBEROS
      KERBEROS_PUBLIC_URL: <<kerberos_public_dns>>
      KERBEROS_REALM: <<kerberos_realm>>
      KAFKA_KERBEROS_PRINCIPAL: <<kafka_kerberos_principal_name>>@<<kerberos_realm>>
    volumes:
      - ./kafka.service.keytab:/sasl/kafka.service.keytab
```

#### docker-compose kafka and zookeeper kerberos example

This is a kerberos setup where zookeeper is a kerberos enabled zookeeper server. Please note that without access control lists this is not more secure because anonymous users are allowed on a kerberos enabled zookeeper. See ACL example for a secure setup with a zookeeper kerberos enabled server.

It is the same setup as above but with 'ZOOKEEPER_KERBEROS_PRINCIPAL' added and an additonal keytab provided through volumes.

```
version: "3"

services:
  kafka:
    image: cfei/kafka
    ports:
      - 9092:9092
      - 9093:9093
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: <<zookeeper1_ip>>:2181,<<zookeeper2_ip>>:2181,<<zookeeper3_ip>>:2181
      KAFKA_LISTENERS: INTERNAL://0.0.0.0:9092,SASL_PLAINTEXT://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://<<server_ip>>:9092,SASL_PLAINTEXT://<<server_ip>>:9093
      KAFKA_AUTHENTICATION: KERBEROS
      KERBEROS_PUBLIC_URL: <<kerberos_public_dns>>
      KERBEROS_REALM: <<kerberos_realm>>
      KAFKA_KERBEROS_PRINCIPAL: <<kafka_kerberos_principal_name>>@<<kerberos_realm>>
      ZOOKEEPER_KERBEROS_PRINCIPAL:  <<zookeeper_kerberos_principal_name>>@<<kerberos_realm>>
    volumes:
      - ./kafka.service.keytab:/sasl/kafka.service.keytab
      - ./zookeeper.service.keytab:/sasl/zookeeper.service.keytab
```

## <a name="acl"></a> ACL (Access Control Lists)

In order for Access Control Lists to work you need to have authentication working first [See Kerberos setup](#kerberos).
When Kerberos has been setup correctly, you can then use the two environment variable `KAFKA_ACL_ENABLE` and `KAFKA_ACL_SUPER_USERS` to use Access Control Lists.

#### docker-compose kafka acl example

```
version: "3"

services:
  kafka:
    image: cfei/kafka
    ports:
      - 9092:9092
      - 9093:9093
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: <<zookeeper1_ip>>:2181,<<zookeeper2_ip>>:2181,<<zookeeper3_ip>>:2181
      KAFKA_LISTENERS: INTERNAL://0.0.0.0:9092,SASL_PLAINTEXT://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://<<server_ip>>:9092,SASL_PLAINTEXT://<<server_ip>>:9093
      KAFKA_AUTHENTICATION: KERBEROS
      KERBEROS_PUBLIC_URL: <<kerberos_public_dns>>
      KERBEROS_REALM: <<kerberos_realm>>
      KAFKA_KERBEROS_PRINCIPAL: <<kafka_kerberos_principal_name>>@<<kerberos_realm>>
      ZOOKEEPER_KERBEROS_PRINCIPAL:  <<zookeeper_kerberos_principal_name>>@<<kerberos_realm>>
      KAFKA_ACL_ENABLE: "true"
      KAFKA_ACL_SUPER_USERS: User:kafka
    volumes:
      - ./kafka.service.keytab:/sasl/kafka.service.keytab
      - ./zookeeper.service.keytab:/sasl/zookeeper.service.keytab
```