#!/bin/bash
set -eu

setup() {
  echo "setting up test"
  if [ -d $JENKINS_HOME/charms/oneiric/$charm_name ]; then
    rm -Rf $JENKINS_HOME/charms/oneiric/$charm_name
  fi
  charm get $charm_name $JENKINS_HOME/charms/oneiric/$charm_name
  juju bootstrap
}

run_test() {
  echo "running test"
  juju deploy --repository $JENKINS_HOME/charms local:$charm_name

  $JENKINS_HOME/juju-service-started $charm_name || fail
}

fail() {
  echo "test failed"
  # copy log files somewhere
  exit 1
}

teardown() {
  echo "tearing down test"
  yes | juju destroy-environment
  if [ -d $JENKINS_HOME/charms/oneiric/$charm_name ]; then
    rm -Rf $JENKINS_HOME/charms/oneiric/$charm_name
  fi
}


trap teardown EXIT INT TERM
setup
run_test
trap - EXIT INT TERM

teardown
exit 0

