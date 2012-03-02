
# CharmTester

running jenkins... create jobs of the form
    
    $release-$provider-charm-$charm_name

each job:
  - clones all charms into a workspace,
  - generates a set of plans to test the charm alongside its dependent charms
  - spins up and waits on each of these plans to complete

- building

    Use the following URL to trigger build remotely: $JENKINS_URL/job/$job_name/build?token=TOKEN or /buildWithParameters?token=TOKEN
    Optionally append &cause=Cause+Text to provide text that will be included in the recorded build cause.
    http://charmtests.markmims.com/job/jenkins/build?token=TOKEN

- notifications / publication

  - configure ircbot in config yaml
  - configure build-publisher in config yaml
  - watch status directly

    $JENKINS_URL/job/$job_name/api/json
    
    grab the field "color" it's either "red" or "blue"

# TODO

- turn charmrunner into a set of charm-tools subcommands

- infra 
  - persist job stuff between instances (address backups _and_ availability)
    - S3
  - jenkins plugins:
    - openid
  - jenkins slaves working
  - use splice to simplify the charmtester charm itself... need storage, charm testing, jenkins, etc
  - upgrade juju nightly (is there a way to just watch the ppa?)
  - wipe/rebuild the lxc cache regularly
  - wipe/rebuild the master charmset regularly (this is used only to generate dependency graphs)

- how to handle series? different instances?
  - currently requires new environment in config params
  - also need to update watch/snapshot tools



