#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh

install_charmrunner() {
  local user=$1
  local home=$2

  apt-get -qq install -y zip

  rm -Rf /tmp/charmrunner
  #bzr branch lp:charmrunner /tmp/charmrunner
  bzr branch lp:~mark-mims/charmrunner/no-local-dns /tmp/charmrunner
  ( cd /tmp/charmrunner && python setup.py install )
}

install_charm_job_updater() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/lib
  install --mode=644 --owner=$user --group=nogroup lib/ch-file.sh $home/lib/
  install --mode=644 --owner=$user --group=nogroup lib/juju-provider-info.sh $home/lib/
  install --mode=644 --owner=$user --group=nogroup lib/charm-job.sh $home/lib/

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/update-charm-jobs $home/bin/
}

install_test_scheduler() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/run-charm-jobs $home/bin/
  install --mode=755 --owner=$user --group=nogroup files/nightly-update $home/bin/

  mkdir -p -m755 $home/etc
  install --mode=755 --owner=$user --group=nogroup files/crontab $home/etc/
  crontab -u $user $home/etc/crontab

}

install_test_wrapper() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/charm-test $home/bin/
  install --mode=755 --owner=$user --group=nogroup files/watch-for-service-started $home/bin/
}

install_graph_runner() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/charm-graph-tests $home/bin/
}

install_unittest_runner() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/charm-unit-tests $home/bin/
}

install_juju_test_tools() {
  local user=$1
  local home=$2

  juju-log "installing charmrunner"
  install_charmrunner $user $home

  juju-log "installing charm job updater"
  install_charm_job_updater $user $home

  juju-log "installing test scheduler"
  install_test_scheduler $user $home

  juju-log "installing test wrapper"
  install_test_wrapper $user $home

  juju-log "installing charm runner"
  install_graph_runner $user $home

  juju-log "installing unittest runner"
  install_unittest_runner $user $home

}
