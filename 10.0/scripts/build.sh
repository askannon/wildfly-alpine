#!/usr/bin/env sh

set -ex

# if we execute from a child image only run the cli commands
if [ $# -eq 1 ] && [ "$1" = "jboss-cli-only" ]; then
  cd /opt/jboss-cli
  for configfile in `ls`; do
    $JBOSS_HOME/bin/jboss-cli.sh --file=${configfile}
  done
  chown -R $WILDFLY_USER:$WILDFLY_GROUP $JBOSS_HOME /opt/wildfly-$WILDFLY_VERSION
  rm -rf $JBOSS_HOME/standalone/configuration/standalone_xml_history /opt/jboss-cli/*
  exit 0
fi

# get some additional alpine packages
apk update
apk upgrade
apk add --update \
  curl \
  bash \
  tcpdump \
  lsof \
  ngrep \
  unzip \
  socat

# install the S6 overlay
curl -L https://github.com/just-containers/s6-overlay/releases/download/v$S6_VERSION/s6-overlay-amd64.tar.gz | tar xz -C /

# install WildFly
mkdir -p /opt/jboss-cli
curl https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar xz -C /opt
cd /opt
ln -s wildfly-$WILDFLY_VERSION wildfly

# process some default configuration settings
cd $JBOSS_HOME/standalone/configuration/

# this applys to all config files
for configfile in `ls standalone*.xml`; do
  $JBOSS_HOME/bin/jboss-cli.sh <<- _EOF_
    embed-server --server-config=${configfile}
    /subsystem=transactions/:write-attribute(name=node-identifier,value="\${jboss.node.name}")
    /subsystem=undertow/server=default-server/host=default-host/filter-ref=server-header:remove()
    /subsystem=undertow/server=default-server/host=default-host/filter-ref=x-powered-by-header:remove()
    /subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=proxy-address-forwarding,value=true)
    /subsystem=undertow/server=default-server/http-listener=default:undefine-attribute(name=redirect-socket)
_EOF_
done

# this only applies to HA config files
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
    /subsystem=infinispan/cache-container=web/distributed-cache=dist/transaction=TRANSACTION:add(locking=OPTIMISTIC)
    /subsystem=infinispan/cache-container=web/distributed-cache=dist/locking=LOCKING:add(isolation=READ_COMMITTED)
    run-batch
_EOF_
done

# install jolokia agent
curl -L http://central.maven.org/maven2/org/jolokia/jolokia-war/$JOLOKIA_VERSION/jolokia-war-$JOLOKIA_VERSION.war -o /tmp/jolokia.war
unzip /tmp/jolokia.war -d $JBOSS_HOME/standalone/deployments/jolokia.war

# add run as user/group
addgroup -g $WILDFLY_GID $WILDFLY_GROUP
adduser -D -G $WILDFLY_GROUP -s /bin/false -u $WILDFLY_UID $WILDFLY_USER
chown -R $WILDFLY_USER:$WILDFLY_GROUP $JBOSS_HOME /opt/wildfly-$WILDFLY_VERSION

# cleanup
rm -rf /tmp/* /var/cache/apk/* $JBOSS_HOME/standalone/configuration/standalone_xml_history
