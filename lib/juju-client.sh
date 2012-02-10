#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh

install_juju_packages() {
  juju-log "Installing juju for local testing..."
  apt-add-repository ppa:juju/pkgs
  # Might not pickup for current release - so ignore errors
  apt-get update || true
  apt-get -qq install -y juju charm-tools apt-cacher-ng zookeeper libvirt-bin lxc charm-helper-sh
}

generate_ssh_keys() {
  local user=$1
  local home=$2
  if [ ! -f $home/.ssh/id_rsa ]; then
    su -l $user -c "ssh-keygen -q -N '' -t rsa -b 2048 -f $home/.ssh/id_rsa"
  fi
}

create_charms_repo() {
  local user=$1
  local home=$2
  mkdir -p $home/charms/oneiric
  chown -Rf $user:$user $home
}

configure_juju_environment() {
  local user=$1
  local home=$2
  mkdir -p $home/.juju
  ch_template_file 755 $user.$user environments.yaml $home/.juju/environments.yaml "home"
  generate_ssh_keys $user $home
  create_charms_repo $user $home
}

####
# specific to local provider

make_user_sudo() {
  local user=$1
  local sudoer_file="/etc/sudoers.d/91-$user-charmtester"
  echo "$user ALL=(ALL) NOPASSWD:ALL" > $sudoer_file
  chmod 0440 $sudoer_file
}

use_tmpfs_for_tests() {
  grep -q lxc /etc/fstab || echo "tmpfs /var/lib/lxc tmpfs size=2g 0 0" >> /etc/fstab
  # maybe do the same for /var/cache/lxc?
  mount -at tmpfs 
}

configure_juju_local_provider() {
  local user=$1
  addgroup $user libvirtd 
  make_user_sudo $user
  use_tmpfs_for_tests
}

configure_juju_provider() {
  local user=$1
  configure_juju_local_provider $user
}

# specific to local provider
####

install_juju_client() {
  local user=$1
  local home=$2

  juju-log "installing juju packages"
  install_juju_packages

  juju-log "cofiguring juju provider"
  configure_juju_provider $user

  juju-log "configuring juju environment"
  configure_juju_environment $user $home

}
