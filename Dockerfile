FROM ubuntu:18.04

ENV KAFKA_HOME=/opt/kafka

RUN apt update && \
    apt install -y --no-install-recommends openjdk-8-jre-headless && \
    apt install -y jq

# Copy necessary scripts + configuration
COPY scripts server.properties /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/*.sh /usr/bin && \
    rm -rf /tmp/*.sh

# Install kafka
# ADD https://archive.apache.org/dist/kafka/2.4.0/kafka_2.12-2.4.0.tgz /opt/
COPY ./kafka_2.12-2.4.0.tgz /opt/
RUN cd /opt && \
    tar -xzf kafka_2.12-2.4.0.tgz && \
    mv kafka_2.12-2.4.0 kafka && \
    rm -rf /opt/*.tar && \
    mv /tmp/server.properties /opt/kafka/config/server.properties

EXPOSE 9092

HEALTHCHECK --interval=45s --timeout=35s --start-period=15s --retries=2 CMD [ "healthcheck.sh" ]

VOLUME [ "/data/kafka" ]

WORKDIR /opt/kafka

CMD [ "start.sh" ]

