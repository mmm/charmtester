
#!/bin/bash

[ -f /usr/share/charm-helper/bash/file.bash ] && . /usr/share/charm-helper/bash/file.bash || . lib/ch-file.sh

install_charmrunner() {
  local user=$1
  local home=$2

  apt-get -qq install -y zip

  rm -Rf /tmp/charmrunner
  bzr branch $(config-get charmrunner_source) /tmp/charmrunner
  ( cd /tmp/charmrunner && python setup.py install )
}

install_charm_job_updater() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/lib
  chown $user.nogroup $home/lib
  install --mode=644 --owner=$user --group=nogroup lib/ch-file.sh $home/lib/
  install --mode=644 --owner=$user --group=nogroup lib/juju-provider-info.sh $home/lib/
  install --mode=644 --owner=$user --group=nogroup lib/charm-job.sh $home/lib/
  install --mode=644 --owner=$user --group=nogroup lib/build-helper.sh $home/lib/

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/update-charm-jobs $home/bin/
}

install_test_scheduler() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/run-charm-job $home/bin/
  install --mode=755 --owner=$user --group=nogroup files/run-charm-jobs $home/bin/
  install --mode=755 --owner=$user --group=nogroup files/run-priority-charm-jobs $home/bin/
  install --mode=755 --owner=$user --group=nogroup files/nightly-update $home/bin/

  mkdir -p -m755 $home/etc
  install --mode=755 --owner=$user --group=nogroup files/crontab $home/etc/
  crontab -u $user $home/etc/crontab

}

install_test_wrapper() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  local goju_enabled=`config-get goju_enabled`
  if [ -n "$goju_enabled" ]; then
    install --mode=755 --owner=$user --group=nogroup files/goju-charm-test $home/bin/charm-test
    install --mode=755 --owner=$user --group=nogroup files/goju-watch-for-service-started $home/bin/watch-for-service-started
  else
    install --mode=755 --owner=$user --group=nogroup files/charm-test $home/bin/
    install --mode=755 --owner=$user --group=nogroup files/watch-for-service-started $home/bin/
  fi
}

install_graph_runner() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  local goju_enabled=`config-get goju_enabled`
  if [ -n "$goju_enabled" ]; then
    install --mode=755 --owner=$user --group=nogroup files/goju-charm-graph-tests $home/bin/charm-graph-tests
  else
    install --mode=755 --owner=$user --group=nogroup files/charm-graph-tests $home/bin/
  fi
}

install_log_archiver() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/juju-slurp-logs $home/bin/
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

  juju-log "installing log archiver"
  install_log_archiver $user $home
}
