#!/bin/bash

set -u

cryptozoologist() {
  if [ ! -f $WORKSPACE/.crypto ]; then
    touch $WORKSPACE/.crypto
    echo "Archiving Logs"
    archive_logs $WORKSPACE
    echo "Archiving Plans"
    archive_plans $WORKSPACE
    echo "Archiving Charm"
    archive_charm $WORKSPACE
  else
    echo "We've already got logs."
  fi
}

archive_logs() {
  local destination=$1
  if [ ! -d $destination/logs ]; then
    $HOME/bin/juju-slurp-logs --dir $destination/logs
    if [ ! -d $destination/logs ]; then
      mkdir -p $destination/logs
      echo "No logs were slurped." | tee $destination/logs/sorry
    fi
  fi
  ( cd $destination && tar czvf $destination/$(basename $0)-logs.tar.gz logs )
  #sudo chown -Rf jenkins.nogroup $destination
}

archive_plans() {
  local destination=$1
  if [ -d $WORKSPACE/testdir/plans ]; then
    ( cd $WORKSPACE/testdir/plans; zip -r $destination/$(basename $0)-plans.zip . )
  fi
}

archive_charm() {
  local destination=$1
  if [ -f $HOME/.tpaas ]; then
    charm_dir="$destination/$charm_name"
  else
    series="precise"
    charm_dir="$HOME/charms/$series/$charm_name"
  fi

  if [ -d $charm_dir ]; then
    ( cd $charm_dir ; bzr revision-info > $destination/charm-revision )
    ( cd $charm_dir ; zip -r $destination/charm-$charm_name.zip . )
  else
    # There was no charm. But the version of Jenkins can't handle this.
    # Seriously, it breaks if there aren't any artificts. This was _just_
    # fixed in the latest version of Jenkins 2013-03-31 but we're lightyears
    # behind that in this charm. So FAKE IT UNTIL YOU MAKE IT!
    echo `date "+%Y-%m-%d %H:%M:%S %Z"` > $destination/charm-revision
    touch probably-deployed-from-store.zip
  fi
}

generate_plans() {
  echo "generating test plans"
  rm -Rf $WORKSPACE/testdir/plans
  mkdir -p $WORKSPACE/testdir/plans
  if [ -f $HOME/.tpaas ]; then
    tpaas=`cat $HOME/.tpaas`
    # TODO: This is hardcoded series, same with the archive charm function. Needs to be fixed eventually
    wget $tpaas/plan/precise/$charm_name -O $WORKSPACE/testdir/plans/${charm_name}-0.plan
  else
    juju-plan --repo $HOME/charms -s precise -d $WORKSPACE/testdir/plans $charm_name
  fi
}

run_test_plan() {
  local plan=$1

  if [ -f $HOME/.tpaas ]; then
    juju-load-plan $WORKSPACE/testdir/plans/$plan
  else
    juju-load-plan -r $HOME/charms $WORKSPACE/testdir/plans/$plan
  fi

  timeout 15m $HOME/bin/watch-for-service-started "$charm_name/0"
  return $?
}

run_graph_tests() {
  echo "running test"
  for plan in `ls $WORKSPACE/testdir/plans`; do
    run_test_plan $plan
  done
}

check_timeout() {
  sig=$?
  if [ $sig -eq 124 ]; then
    unstable
  else
    fail
  fi
}

setup() {
  # Add a loop w/t counter and check $? for each command. Make sure we
  # get a clean environment.
  yes | juju destroy-environment; echo
  sleep 60
  juju bootstrap || true
}

destroy() {
  yes | juju destroy-environment; echo
}

teardown() {
  cryptozoologist $WORKSPACE
  destroy
}

fail() {
  cryptozoologist
  echo "TEST FAILED"
  exit 1
}

unstable() {
  cryptozoologist
  java -jar $HOME/jenkins-cli.jar -s http://localhost:8080 set-build-result unstable
  sleep 10
  exit 0
}
