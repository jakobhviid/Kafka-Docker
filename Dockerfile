FROM ubuntu:18.04

ENV KAFKA_HOME=/opt/kafka

RUN apt update && \
    apt install -y --no-install-recommends openjdk-11-jre-headless && \
    apt install -y jq && \
    apt install -y openssh-client

# Copy necessary scripts + configuration
COPY scripts server_setup/server.properties /tmp/
RUN chmod +x /tmp/*.sh && \
    mv /tmp/*.sh /usr/bin && \
    rm -rf /tmp/*.sh

# Install kafka
COPY ./kafka_2.12-2.4.0.tgz /opt/
RUN cd /opt && \
    tar -xzf kafka_2.12-2.4.0.tgz && \
    mv kafka_2.12-2.4.0 ${KAFKA_HOME} && \
    rm -rf /opt/*.tar && \
    mv /tmp/server.properties ${KAFKA_HOME}/config/server.properties && \
    mkdir /keytabs

EXPOSE 9092 9093
# # SSL. ssl is where everything related to kafka broker is, certificate_authorizer is everything related to mimicking a certificate authorizer which will be shared among all brokers and clients
# RUN mkdir /ssl && mkdir /certificate_authorizer

COPY ./server_setup/kafka_server_jaas.conf ${KAFKA_HOME}/config
COPY ./server_setup/kafka.service.keytab /keytabs/kafka.service.keytab

EXPOSE 9092 9093

HEALTHCHECK --interval=45s --timeout=35s --start-period=15s --retries=2 CMD [ "healthcheck.sh" ]

VOLUME [ "/data/kafka" ]

WORKDIR ${KAFKA_HOME}

CMD [ "start.sh" ]