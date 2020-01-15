#!/bin/bash

IFS=',' # Internal field seperator
read -r -a zookeepers <<< "$KAFKA_ZOOKEEPER_CONNECT" # Save to array called zookeepers

# TODO - Write it so that it checks other zookeepers but only if the first zookeeper service is down.
for zookeeperServer in "${zookeepers[@]}"
do
    # Get a list of brokers id's from zookeeper and check if the JSON array contains the broker id
    brokerIdFound=`/opt/kafka/bin/zookeeper-shell.sh $zookeeperServer <<< "ls /brokers/ids" | tail -1 | jq --argjson broker_id $KAFKA_BROKER_ID 'contains([$broker_id])'`

    if [ "$brokerIdFound" = true ] # BrokerId was found which means the broker is running
    then 
        echo " OK "
        exit 0
    fi

    # TODO - 1. Check the executable actually runs (px -x, led efter kafka (Searchstring)) 
    # TODO - 2. Check logic, consumer for example (/)
    # /opt/kafka/bin/kafka-topics.sh --create --topic HEALTHCHECK --bootstrap-server localhost:9092
    # /opt/kafka/bin/kafka-topics.sh --list --topic HEALTHCHECK --bootstrap-server localhost:9092 | grep HEALTHCHECK (Check it's there)
    # /opt/kafka/bin/kafka-topics.sh --delete --topic HEALTHCHECK --bootstrap-server localhost:9092
done

# If not one of the zookeeper connections could see the broker being up that must mean the broker is down
echo "BAD"
exit 1