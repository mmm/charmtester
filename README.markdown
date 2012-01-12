
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

