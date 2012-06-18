#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh

install_test_scheduler() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/run-charm-jobs $home/bin/

  mkdir -p -m755 $home/etc
  install --mode=755 --owner=$user --group=nogroup files/crontab $home/etc/
}

install_test_wrapper() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/charm-test $home/bin/
}

install_installation_runner() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/charm-installation-test $home/bin/
}

install_graph_runner() {
  local user=$1
  local home=$2

  rm -Rf /tmp/charmrunner
  bzr branch lp:charmrunner /tmp/charmrunner
  #bzr branch lp:~mark-mims/charmrunner/with-environment /tmp/charmrunner
  ( cd /tmp/charmrunner && python setup.py install )

  install --mode=755 --owner=$user --group=nogroup files/charm-graph-test $home/bin/
}


install_juju_test_tools() {
  local user=$1
  local home=$2

  juju-log "installing test scheduler"
  install_test_scheduler $user $home

  juju-log "installing test wrapper"
  install_test_wrapper $user $home

  juju-log "installing local runner"
  install_installation_runner $user $home

  juju-log "installing charm runner"
  install_graph_runner $user $home

}
