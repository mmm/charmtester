#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh

provider_types() {
  local home=$1
  cat $home/.juju/environments.yaml | awk '/\ type:\ / { print $2 }'
}

job_name_for_charm() {
  local charm_name=$1
  local provider=$2
  local series=$(config-get test_series)
  echo "$series-$provider-charm-$charm_name"
}

get_api_token() {
  local home=$1
  cat $home/API_TOKEN
}

create_job_for_charm() {
  local charm_name=$1
  local user=$2
  local home=$3
  local provider=$4
  local job_name=$(job_name_for_charm $charm_name $provider)
  local API_TOKEN=$(get_api_token $home)
  local build_publisher_enabled=$(config-get build_publisher_enabled)
  local ircbot_enabled=$(config-get ircbot_enabled)
  mkdir -p -m755 $home/jobs/$job_name
  ch_template_file 755 \
                   $user:nogroup \
                   job-config.xml \
                   $home/jobs/$job_name/config.xml \
                   "user home provider charm_name job_name API_TOKEN build_publisher_enabled ircbot_enabled"
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

  for charm_name in `su -l $user -c "charm list | grep lp:charms | sed 's/lp:charms\///'"`; do
    if blacklisted_charm $charm_name ; then
      juju-log "skipping blacklisted $charm_name"
    else
      for provider in `provider_types $home`; do
        create_job_for_charm $charm_name $user $home $provider
      done
    fi
  done
  chown -Rf $user:nogroup $home/jobs/
}

