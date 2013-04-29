#!/bin/bash

[ -f lib/ch-user.sh ] && . lib/ch-user.sh
[ -f /usr/share/charm-helper/bash/file.bash ] && . /usr/share/charm-helper/bash/file.bash || . lib/ch-file.sh
[ -f lib/juju-provider.sh ] && . lib/juju-provider.sh


install_pyju_packages() {
  juju-log "Installing python juju..."
  apt-add-repository ppa:juju/pkgs
  # Might not pickup for current release - so ignore errors
  apt-get update || true
  apt-get -qq install -y juju charm-tools apt-cacher-ng zookeeper libvirt-bin lxc charm-helper-sh
  apt-get -qq install -y --no-install-recommends juju-jitsu
}

install_goju_packages() {
  juju-log "Installing go juju..."
  apt-add-repository ppa:gophers/go
  apt-get update || true
  apt-get -qq install -y juju-core
  #apt-get -qq install -y --no-install-recommends juju-jitsu
}

prefix_command_path() {
  local user=$1
  local home=$2
  echo 'export PATH=$HOME/bin:$PATH' >> $home/.bashrc
}

install_goju_from_source() {
  local user=$1
  local home=$2
  juju-log "Installing go juju from source..."

  # might need to pass a debconf-setting to golang-go
  # golang-go       golang-go/dashboard     boolean false
  apt-get -qq install -y golang-go build-essential bzr zip git-core mercurial 
  apt-get -qq install -y charm-tools charm-helper-sh

  #sudo -HEsu $user "export GOPATH=$home && go get -v launchpad.net/juju-core/... && go install -v launchpad.net/juju-core/..."
  prefix_command_path $user $home
}

install_juju_packages() {
  local user=$1
  local home=$2
  juju-log "Installing juju..."
  local goju_enabled=`config-get goju_enabled`
  if [ -n "$goju_enabled" ]; then
    install_goju_from_source $user $home
  else
    install_pyju_packages
  fi
}

install_juju_environment_tools() {
  local user=$1
  local home=$2
  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/juju-environment $home/bin/
}

configure_juju_environment() {
  local user=$1
  local home=$2
  local juju_environments_file=$home/.juju/environments.yaml
  mkdir -p $home/.juju
  chown $user:$user $home/.juju

  local juju_environments=$(config-get tester_environment)
  if [ -z "$juju_environments" ]; then
    ch_template_file 644 $user:nogroup templates/default-local-environment.yaml $juju_environments_file "home"
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
  install_juju_packages $user $home

  juju-log "installing juju environment tools"
  install_juju_environment_tools $user $home

  juju-log "configuring juju environment"
  configure_juju_environment $user $home

  juju-log "cofiguring juju providers"
  configure_juju_providers $user $home

  juju-log "done installing juju client tools"
}
