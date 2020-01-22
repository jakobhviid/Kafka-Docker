#!/bin/bash

IFS=',' # Internal field seperator
read -r -a zookeepers <<< "$KAFKA_ZOOKEEPER_CONNECT" # Save to array called zookeepers

for zookeeperServer in "${zookeepers[@]}"
do
    # Get a list of brokers id's from zookeeper and check if the JSON array contains the broker id
    brokerIdFound=`/opt/kafka/bin/zookeeper-shell.sh $zookeeperServer <<< "ls /kafka/brokers/ids" | tail -1 | jq --argjson broker_id $KAFKA_BROKER_ID 'contains([$broker_id])'`

    if [ "$brokerIdFound" = true ] # BrokerId was found which means the broker is running
    then
        # Test kafka runs in container correctly
        kafkaProcess=`ps -x | grep java | grep kafka`

        # If kafkaProcess is not empty
        if ! [[ -z "$kafkaProcess" ]]
        then
            # Check logic. Healthcheck will time out if server is not available.
            topicName="TEST-HEALTHCHECK-BROKER-$KAFKA_BROKER_ID"
            /opt/kafka/bin/kafka-topics.sh --create --topic $topicName --bootstrap-server localhost:9092 --partitions 10 --replication-factor 1

            # If somehow the topic already exists it will throw an error when creating, but if this checks goes through that means the server is still operating fine and will therefore not be considered unhealthy
            topic=`/opt/kafka/bin/kafka-topics.sh --list --topic $topicName --bootstrap-server localhost:9092 | grep "$topicName"`

           # If topic is empty
           if [[ -z "$topic" ]]
            then
                echo " ERROR Could not find created topic in list "
                exit 1
            fi

            # Topic deleted for the future
            /opt/kafka/bin/kafka-topics.sh --delete --topic $topicName --bootstrap-server localhost:9092

            # # Check if topic has been deleted
            # topic=`/opt/kafka/bin/kafka-topics.sh --list --topic $topicName --bootstrap-server localhost:9092 | grep "$topicName"`
            # if ! [[ -z "$topic" ]] # If topic is not empty
            # then
            #     echo " ERROR Found topic in list after deletion "
            #     exit 1
            # fi

            echo " OK "
            exit 0
        fi
    fi
done

# If not one of the zookeeper connections could see the broker being up that must mean the broker is down
echo " KAFKA SERVER NOT RUNNING PROPERLY "
exit 1