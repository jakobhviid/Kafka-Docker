# How to use
A docker-compose file have been provided as an example. **NOTE:** Kafka requires atleast one running zookeeper node in order to work. [Zookeeper Image](https://hub.docker.com/repository/docker/cfei/zookeeper)
 
This docker-compose demonstrates deployment of a single Kafka broker.

It is necessary to open ports on the host machine. 9092 (client connections) and 9093 (broker-broker communication)

Quite a few environment variabels are required in order for Kafka to work properly in a cluster and they are important to get right. Some environemnt variables can also be set but is not required as defaults work out of the box.

# Configuration
**Configurations for a clustered setup**

* `KAFKA_BROKER_ID:` A unique and permanent number, naming the node in the cluster.

* `KAFKA_ZOOKEEPER_CONNECT:` Comma-seperated list of Zookeeper URIs' which Kafka will connect to. Kafka will connect to the first available zookeeper. If that goes down it will go to the next and connect to it. This connection string can end with a chroot path which makes Kafka brokers put all their data in their own namespace in Zookeeper.

* `KAFKA_ADVERTISED_LISTENERS:` Advertised listeners for clients to use. This value is given to zookeeper so that clients can discover Kafka brokers.

* `KAFKA_LISTENERS:` Comma-seperated list of URIs' on which Kafka will listen. Wildcard IP-address are allowed. 

* `KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR:` Replication factor for the essential topic 'consumer_offsets'. Should have a value of atleast 2 to ensure availability. Default is 1 for single broker deployments.

* `KAFKA_MIN_INSYNC_REPLICAS:` Minimum number of replicas (brokers) that must acknowledge writes. Enforces greater durability and should atleast be 2. Default is 1 for single broker deployments.

**Configurations with defaults for a clustered setup**

* `KAFKA_RETENTION_HOURS:` Number of hours to keep a log file before deleting it. The higher retention hours the longer data will stay in kafka. Default is 168 hours (7 days).

* `KAFKA_LISTENER_SECURITY_PROTOCOL_MAP:` A mapping between listener names and security protocols. Required when brokers is set up with SSL. Default is INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT.

* `KAFKA_INTER_BROKER_LISTENER_NAME:` The name of the listener used for broker-broker communication. Default is 'INTERNAL'.

* `KAFKA_DEFAULT_REPLICATION_FACTOR:` If a topic isn't created explicitly and therefore created automatically, the default replication factor will be used. Default is 1.

#### TODO - Give an example of configuring with encryption (Securtiy Protocol Map, Advertised Listeners etc.)

