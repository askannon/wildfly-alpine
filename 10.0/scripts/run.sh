#!/usr/bin/env bash

echo "Environment:"
echo "======================"
env | sort
echo "======================"

if [[ ${CONFIG_FILE} ]] && [[ ${CONFIG_FILE} == *ha.xml ]]; then
  if [[ -z $GOSSIP_ROUTERS ]]; then
    echo "If you are using a HA configuration you also have to define a 'GOSSIP_ROUTERS' variabel that contains the connection string"
    exit 1
  else
    HA_OPTIONS="-Djgroups.gossip_router_hosts=$GOSSIP_ROUTERS"
  fi
fi

exec s6-applyuidgid -u 1000 -g 1000 $JBOSS_HOME/bin/standalone.sh $HA_OPTIONS -Djava.security.egd=file:/dev/./urandom -Djboss.node.name=$HOSTNAME -b $(hostname -i) -bmanagement $(hostname -i) -c ${CONFIG_FILE:-standalone.xml}

