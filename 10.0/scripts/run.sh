#!/usr/bin/env bash

echo "OS Environment:"
echo "========================================================================="
env | sort
echo "========================================================================="

# add portential statup delays
ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS -Djava.security.egd=file:/dev/./urandom";
# add Jolokia Agent options
#ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS $(/jolokia_opts.sh)";

if [[ ${CONFIG_FILE} ]] && [[ ${CONFIG_FILE} == *ha.xml ]]; then
  if [[ -z $GOSSIP_ROUTERS ]]; then
    echo "If you are using an HA configuration you also have to define a 'GOSSIP_ROUTERS' variabel that contains the connection string (e.g. GOSSIP_ROUTERS=\"10.20.120.2[12001],10.20.120.2[12001]\""
    exit 1
  else
    # add the gossip routers
    ADDL_JAVA_OPTS="$ADDL_JAVA_OPTS -Djgroups.gossip_router_hosts=$GOSSIP_ROUTERS"
  fi
fi

if [[ $JOLOKIA_OFF ]]; then
  touch $JBOSS_HOME/standalone/deployments/jolokia.war.skipdeploy
fi

exec s6-applyuidgid -u 1000 -g 1000 $JBOSS_HOME/bin/standalone.sh -Djboss.node.name=${NODE_NAME:-$HOSTNAME} -b $(hostname -i) -bmanagement $(hostname -i) -c ${CONFIG_FILE:-standalone.xml} $ADDL_JAVA_OPTS
