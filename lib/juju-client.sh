#!/bin/bash

[ -f lib/ch-user.sh ] && . lib/ch-user.sh
[ -f lib/ch-file.sh ] && . lib/ch-file.sh
[ -f lib/juju-provider.sh ] && . lib/juju-provider.sh

install_juju_packages() {
  juju-log "Installing juju for local testing..."
  apt-add-repository ppa:juju/pkgs
  # Might not pickup for current release - so ignore errors
  apt-get update || true
  apt-get -qq install -y juju charm-tools apt-cacher-ng zookeeper libvirt-bin lxc charm-helper-sh
}

install_juju_environment_tools() {
  local user=$1
  local home=$2
  mkdir -p -m755 $home/bin
  ch_install_file 755 $user:nogroup juju-environment $home/bin/
}

update_charms_repo() {
  local user=$1
  local home=$2

  local juju_environments_file=$home/.juju/environments.yaml
  for release in `releases`; do
    mkdir -p $home/charms/$release
    chown -Rf $user:nogroup $home
    sudo -HEsu $user charm getall $home/charms/$release
  done
}

configure_juju_environment() {
  local user=$1
  local home=$2
  local juju_environments_file=$home/.juju/environments.yaml
  mkdir -p $home/.juju

  local juju_environments=$(config-get tester_environment)
  if [ -z "$juju_environments" ]; then
    ch_template_file 644 $user:nogroup default-local-environment.yaml $juju_environments_file "home"
  else
    echo "$juju_environments" > $juju_environments_file
    chmod 644 $juju_environments_file
    chown $user:nogroup $juju_environments_file
  fi

  generate_ssh_keys $user $home
}

install_juju_client() {
  local user=$1
  local home=$2

  juju-log "installing juju packages"
  install_juju_packages

  juju-log "installing juju environment tools"
  install_juju_environment_tools $user $home

  juju-log "configuring juju environment"
  configure_juju_environment $user $home

  juju-log "updating charms repo"
  update_charms_repo $user $home

  juju-log "cofiguring juju providers"
  configure_juju_providers $user $home

  juju-log "done installing juju client tools"

}
