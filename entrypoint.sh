#!/bin/bash

echo "tahoe $1"

function setConfig {
  key=$(echo $1 | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
  val=$(echo $2 | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')
  sed -e "s/\s*#*\s*$key.*/$key = $val/g" -i $3
}

function setNickname {
  setConfig nickname $1 $2
}

function createIntroducer {
  tahoe create-introducer /introducer
  setConfig nickname introducer /introducer/tahoe.cfg
  setConfig web.port tcp:3456 /introducer/tahoe.cfg
  setConfig tub.port tcp:44190 /introducer/tahoe.cfg
}

set -x

case "$1" in
  introducer)
    [ "$(ls -A /introducer)" ] || createIntroducer
    cp -r /introducer /local_node
    tahoe start /local_node -l /var/log/tahoe.log
    sleep 2
    intro=$(cat /local_node/private/introducer.furl)
    [ -z "$intro" ] && exit 1
    [ "$(ls -A /node)" ] || tahoe create-node /node
    setConfig introducer.furl "$intro" /node/tahoe.cfg
    tail -f /var/log/tahoe.log
    ;;
  node)
    cp -r /node /local_node
    setNickname `hostname` /local_node/tahoe.cfg
    tahoe start /local_node --nodaemon -l -
    ;;
  gateway)
    cp -r /node /local_node
    setNickname `hostname` /local_node/tahoe.cfg

    # Configure the gateway
    setConfig enabled false /local_node/tahoe.cfg # disable everything else
    setConfig web.port tcp:3456 /introducer/tahoe.cfg

    if [ ! -f /local_node/private/aliases ]
    then
      tahoe -d /local_node/ start
      tahoe -d /local_node/ create-alias tahoe
      tahoe -d /local_node/ stop
      sed -e 's/^tahoe: /tahoe passw0rd /g' /local_node/private/aliases > /local_node/private/ftp.accounts
    fi

    echo "[ftpd]" >> /local_node/tahoe.cfg
    echo "enabled = true" >> /local_node/tahoe.cfg
    echo "port = 8021" >> /local_node/tahoe.cfg
    echo "accounts.file = private/ftp.accounts" >> /local_node/tahoe.cfg
    echo "" >> /local_node/tahoe.cfg
    echo "[sftpd]" >> /local_node/tahoe.cfg
    echo "enabled = true" >> /local_node/tahoe.cfg
    echo "port = 8022" >> /local_node/tahoe.cfg
    echo "host_pubkey_file = private/id_rsa.pub" >> /local_node/tahoe.cfg
    echo "host_privkey_file = private/id_rsa" >> /local_node/tahoe.cfg
    echo "accounts.file = private/ftp.accounts" >> /local_node/tahoe.cfg

    ssh-keygen -N ""  -f /local_node/private/id_rsa
    echo "PUBLIC KEY: "
    cat /local_node/private/id_rsa.pub


    tahoe start /local_node --nodaemon -l -
    ;;
  version)
    tahoe version
    ;;
esac