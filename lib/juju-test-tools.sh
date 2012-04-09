#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh

install_installation_runner() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  ch_install_file 755 $user:nogroup charm-installation-test $home/bin/
  ch_install_file 755 $user:nogroup juju-service-started $home/bin/
}

install_graph_runner() {
  local user=$1
  local home=$2

  rm -Rf /tmp/charmrunner
  bzr branch lp:charmrunner /tmp/charmrunner
  ( cd /tmp/charmrunner && python setup.py install )

  ch_install_file 755 $user:nogroup charm-graph-test $home/bin/
}

cache_juju_environment() {
  local user=$1
  local home=$2
  mkdir -p -m755 $home/bin
  ch_install_file 755 $user:nogroup precache-lxc $home/bin/
  [ -f /var/cache/lxc/* ] || sudo -HEsu jenkins $home/bin/precache-lxc 
}

install_juju_test_tools() {
  local user=$1
  local home=$2

  juju-log "installing local runner"
  install_installation_runner $user $home

  juju-log "installing charm runner"
  install_graph_runner $user $home

  juju-log "caching test environment"
  cache_juju_environment $user $home

}
