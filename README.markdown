
# Note

This needs to be reconciled against

    http://bazaar.launchpad.net/~clint-fewbar/juju/charm-tests-spec/view/head:/source/charm-tests.rst


# The goal

Publish charm tests organized around:

  - series
  - provider
  - charm
  - other tags? (i.e., "main")

for each charm in the official charm store.

For each configured test environment (specifying {provider, series}) and each charm in the official charm store, the charm tester will:

  - run charm-install-tests (is this still necessary?)
  - run charm-graph-tests
  - run charm unit-tests 


# Components

- Jenkins
  - publish results
      - #juju
      - jenkins.qa.ubuntu.com
  - `API_TOKEN` to programmatically drive charmtesting

- charmtester (separate from and subordinate to jenkins... eventually)
  - creates(/removes?) jobs based on the current charm list
    one job per charm... `$series-$provider-charm-$charm_name`
  - each job
      - runs charm-graph-tests
      - runs charm unit-tests 
  - configured with environment(s) for this slave to test against
      - accts
      - providers
      - series
  - updates test components regularly(?)... juju, charms, plans
      - currently only on upgrade: (needs to be lighter-weight)
          - juju cli version
          - wipe/rebuild the master charmset regularly (this is used only to generate dependency graphs)
          - wipe/rebuild the lxc cache regularly for local provider
          - destroy and rebootstrap regularly to remove stale state (?)

- charm test runner (curl with an `API_TOKEN` wrapped in a cronjob)

# Tests

- charm-install-test
    - pulls the charm
    - bootstraps
    - spins up the charm and watch status for `started`

- charm-graph-test
    - pulls a master charmset
    - generate test plans based on dep graphs (graph-test is the set of test plans for that charm)
    - job
        - pulls the charms for each run (separate from graph generation)
        - bootstraps
        - spins up each plan in the graph-test, watching for success/fail of each plan

- charm-unit-test
    - just hit `$CHARM_DIR/tests/test` and run screaming?
    - maybe sandbox this a little
    - ?

# TODO

- update charmrunner to work against other providers (currently local-only)

- persist job stuff between instances (address backups _and_ availability)
    - S3?

- charmtester needs to:
    - use lighter-weight updates for test components
    - trigger by commit-hooks
    - only re-run charms that have diffs
    - handle deletions from the charm list

- turn charmrunner into juju-jitsu plugins

- jenkins openid plugin (?)

- jenkins slaves working

- maybe use splice to simplify the charmtester charm itself... need storage, charm testing, jenkins, etc

- use lp tools... is there a way to just watch the ppa?


# misc

- building

    Use the following URL to trigger build remotely: $JENKINS_URL/job/$job_name/build?token=TOKEN or /buildWithParameters?token=TOKEN
    Optionally append &cause=Cause+Text to provide text that will be included in the recorded build cause.
    http://charmtests.markmims.com/job/jenkins/build?token=TOKEN

- notifications / publication

  - watch status directly

    $JENKINS_URL/job/$job_name/api/json
    
    grab the field "color" it's either "red" or "blue"

