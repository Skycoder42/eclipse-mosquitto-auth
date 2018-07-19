#!/bin/sh
set -ex

mkdir /tmp/build
cd /tmp/build

# install dependencies
BUILD_DEPS="curl git build-base libressl-dev postgresql-dev mosquitto-dev"
ALL_DEPS="mosquitto mosquitto-libs postgresql-libs ca-certificates $BUILD_DEPS"

apk --no-cache add $ALL_DEPS

# get the sources
MOSQUITTO_VERSION=$(mosquitto -h | sed -n -e 's/^mosquitto version \(\d*\.\d*\.\d*\).*/\1/p')
PLUGIN_VERSION="0.1.2"

git clone https://github.com/eclipse/mosquitto.git -b "v$MOSQUITTO_VERSION"
git clone https://github.com/jpmens/mosquitto-auth-plug.git -b "$PLUGIN_VERSION"

# build the plugin
cd mosquitto-auth-plug
cp config.mk.in config.mk
sed -i "s/BACKEND_POSTGRES ?= no/BACKEND_POSTGRES ?= yes/" config.mk
sed -i "s/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/" config.mk
sed -i "s~MOSQUITTO_SRC =~MOSQUITTO_SRC = ../mosquitto/~" config.mk
make
install -D -m755 auth-plug.so /usr/local/lib/auth-plug.so
install -D -m755 np /usr/local/bin/np

# prepare the container
mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log
cp /etc/mosquitto/mosquitto.conf /mosquitto/config
chown -R mosquitto:mosquitto /mosquitto
echo 'auth_plugin /usr/local/lib/auth-plug.so' >> /mosquitto/config/mosquitto.conf
echo 'auth_opt_backends postgres' >> /mosquitto/config/mosquitto.conf
echo 'auth_opt_userquery SELECT password FROM account WHERE username = $1 limit 1' >> /mosquitto/config/mosquitto.conf
echo 'auth_opt_aclquery SELECT topic FROM acl WHERE (username = $1) AND rw >= $2' >> /mosquitto/config/mosquitto.conf

# cleanup
apk del $BUILD_DEPS
rm -rf /tmp/*
