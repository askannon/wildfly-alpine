#!/usr/bin/env sh

set -ex

if [ $# -eq 1 ] && [ "$1" = "jboss-cli-only" ]; then
  cd /opt/jboss-cli
  for configfile in `ls`; do
    $JBOSS_HOME/bin/jboss-cli.sh --file=${configfile}
  done
  exit 0
fi

apk update
apk upgrade
apk add --update \
  curl \
  wget \
  bash \
  tree \
  tcpdump \
  lsof \
  ngrep

curl -L https://github.com/just-containers/s6-overlay/releases/download/v$S6_VERSION/s6-overlay-amd64.tar.gz | tar xz -C /

mkdir -p /opt/jboss /opt/jboss-cli
curl https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar xz -C /opt/jboss
cd /opt/jboss
ln -s wildfly-$WILDFLY_VERSION wildfly

/opt/jboss/wildfly/bin/add-user.sh admin masergy --silent

cd /opt/jboss/wildfly/standalone/configuration/

for configfile in `ls standalone*.xml`; do
  $JBOSS_HOME/bin/jboss-cli.sh <<- _EOF_
    embed-server --server-config=${configfile}
    /subsystem=transactions/:write-attribute(name=node-identifier,value="\${jboss.node.name}")
_EOF_
done

for configfile in `ls standalone*ha.xml`; do
  $JBOSS_HOME/bin/jboss-cli.sh <<- _EOF_
    embed-server --server-config=${configfile}
    batch
    /subsystem=jgroups/stack=tunnel:add()
    /subsystem=jgroups/stack=tunnel:add-protocol(type="PING")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="MERGE3")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="FD_SOCK",socket-binding="jgroups-tcp-fd")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="FD")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="VERIFY_SUSPECT")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="pbcast.NAKACK2")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="UNICAST3")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="pbcast.STABLE")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="pbcast.GMS")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="MFC")
    /subsystem=jgroups/stack=tunnel:add-protocol(type="FRAG2")
    /subsystem=jgroups/stack=tunnel/transport=TRANSPORT:add(type="TUNNEL")
    /subsystem=jgroups/stack=tunnel/transport=TRANSPORT/property=gossip_router_hosts:add(value="\${jgroups.gossip_router_hosts}")
    /subsystem=jgroups/channel=ee:write-attribute(name=stack,value=tunnel)
    /subsystem=logging/logger=org.jgroups/:add(category=org.jgroups,level=DEBUG)
    run-batch
_EOF_
done

addgroup -g $WILDFLY_GID $WILDFLY_GROUP
adduser -D -G $WILDFLY_GROUP -s /bin/false -u $WILDFLY_UID $WILDFLY_USER
chown -R $WILDFLY_USER:$WILDFLY_GROUP $JBOSS_HOME /opt/jboss/wildfly-$WILDFLY_VERSION

rm -rf /tmp/* /var/cache/apk/*
