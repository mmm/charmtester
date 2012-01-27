#!/bin/bash
set -eu

bootstrap() {
  juju bootstrap || true
  # leave it up
}

setup() {
  echo "setting up test"
  if [ -d $JENKINS_HOME/charms/oneiric/$charm_name ]; then
    rm -Rf $JENKINS_HOME/charms/oneiric/$charm_name
  fi
  charm get $charm_name $JENKINS_HOME/charms/oneiric/$charm_name
}
bootstrap

run_test() {
  echo "running test"
  juju deploy --repository $JENKINS_HOME/charms local:$charm_name

  $JENKINS_HOME/juju-service-started $charm_name 2> /dev/null && echo "pass" || fail
}

fail() {
  echo "test failed"
  # copy log files somewhere
  exit 1
}

teardown() {
  echo "tearing down test"
  juju destroy-service $charm_name
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

