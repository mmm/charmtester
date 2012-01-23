
# CharmTester

set up a dedicated canonistack environment...

running jenkins
w/ jenkins irc bot plugin

charm needs to slurp charms and load corresponding jobs
[ exempt charmtester :) ]

need a job per charm...

for each charm in lp:charm
  setup:
    spin up an lxc test environment
  test:
    install the charm
    pass if 'started' otherwise fail
  teardown:
    drop the lxc test environment


needed:

tool for the tests to use to tell if a charm came up or not
  - call it 'juju-service-started' or 'juju-service-state-changed' or 'juju-watch-service-state'
  - takes service and/or unit name
  - link off of the juju libs and subscribe to events for that service/unit
  - blocks while service state is 'null' or 'pending'
  - returns 0 when 'started' otherwise 1


# TODO

- build logic
  - what sort of periodic and/or event-based rules?

    Use the following URL to trigger build remotely: JENKINS_URL/job/bitlbee/build?token=TOKEN_NAME or /buildWithParameters?token=TOKEN_NAME
    Optionally append &cause=Cause+Text to provide text that will be included in the recorded build cause.
    http://charmtests.markmims.com/job/jenkins/build?token=TOKEN

- no need for large instance... local lxc environments require serial builds

- get tmpfs solution working as part of the build script

- enable openid plugin for jenkins

- notifications / publication

    http://ec2-174-129-56-104.compute-1.amazonaws.com:8080/job/bitlbee/api/json
    grab the field "color" it's either "red" or "blue"

    http://charmtests.markmims.com/job/jenkins/api/json

