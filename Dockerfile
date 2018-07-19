FROM alpine:edge
MAINTAINER Skycoder42 <skycoder42.de@gmx.de>
LABEL Description="Eclipse Mosquitto MQTT Broker with Auth Plugin for PostgreSQL"

COPY setup.sh /tmp/setup.sh
RUN /tmp/setup.sh

ENTRYPOINT ["/usr/sbin/mosquitto"]
CMD ["-c", "/mosquitto/config/mosquitto.conf"]
