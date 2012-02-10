#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh

job_name_for_charm() {
  local charm_name=$1
  echo "oneiric-charm-$charm_name"
}

get_api_token() {
  local home=$1
  cat $home/API_TOKEN
}

create_job_for_charm() {
  local charm_name=$1
  local user=$2
  local home=$3
  local job_name=$(job_name_for_charm $charm_name)
  local API_TOKEN=$(get_api_token $home)
  mkdir -p -m755 $home/jobs/$job_name
  ch_template_file 755 \
                   $user.$user \
                   job-config.xml \
                   $home/jobs/$job_name/config.xml \
                   "user home charm_name job_name API_TOKEN"
}

blacklisted_charm() {
  local charm_name=$1
  for blacklisted_charm in `cat etc/local-blacklisted-charms`; do
    if [ $blacklisted_charm == $charm_name ]; then
      return 0
    fi
  done
  return 1
}

update_charm_jobs() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  ch_install_file 755 $user.$user charm-test $home/bin/
  ch_install_file 755 $user.$user juju-service-started $home/bin/

  for charm_name in `su -l $user -c "charm list | grep lp:charms | sed 's/lp:charms\///'"`; do
    blacklisted_charm $charm_name && juju-log "skipping blacklisted $charm_name" || create_job_for_charm $charm_name $user $home
  done
  chown -Rf $user.$user $home/jobs/
}

