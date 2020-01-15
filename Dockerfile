FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-8-jre-headless

# Test if mirror is working and use other mirrors if the optimal ones are down
ADD https://archive.apache.org/dist/kafka/2.4.0/kafka_2.12-2.4.0.tgz /opt/

# Install kafka
RUN cd /opt && \
    tar -xzf kafka_2.12-2.4.0.tgz && \
    mv kafka_2.12-2.4.0 kafka && \
    rm -rf /opt/*.tgz

# Setup server-properties in accordance with environment variables
COPY server-properties-init.sh /tmp/

ARG ZOOKEEPER_CONNECT_URI
ENV ZOOKEEPER_CONNECT_URI=$ZOOKEEPER_CONNECT_URI
ARG BROKER_ID
ENV BROKER_ID=$BROKER_ID
ARG OFFSETS_TOPIC_REPLICATION_FACTOR
ENV OFFSETS_TOPIC_REPLICATION_FACTOR=$OFFSETS_TOPIC_REPLICATION_FACTOR

RUN chmod +x /tmp/*.sh && \
    /tmp/server-properties-init.sh && \
    rm -rf /tmp/*

WORKDIR /opt/kafka

ENTRYPOINT [ "bin/kafka-server-start.sh" ]
CMD [ "config/server.properties" ]

