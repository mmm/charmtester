#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh
[ -f lib/juju-provider.sh ] && . lib/juju-provider.sh

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

charm_listed_in_file() {
  local charm_name=$1
  local file=$2

  for charm in `cat ${file}`; do
    if [ $charm == $charm_name ]; then
      return 0
    fi
  done

  return 1
}

blacklisted_charm() {
  local charm_name=$1
  local provider=$2

  local provider_blacklist="etc/${provider}-blacklisted-charms"
  [ -f $provider_blacklist ] && charm_listed_in_file $charm_name $provider_blacklist && return 0

  local global_blacklist="etc/common-blacklisted-charms"
  [ -f $global_blacklist ] && charm_listed_in_file $charm_name $global_blacklist && return 0

  return 1
}

update_charm_jobs() {
  local user=$1
  local home=$2

  for charm_name in `su -l $user -c "charm list | grep lp:charms | sed 's/lp:charms\///'"`; do
    for provider in `provider_types $home`; do
      if blacklisted_charm $charm_name $provider ; then
        juju-log "skipping blacklisted $charm_name for provider $provider"
      else
        create_job_for_charm $charm_name $user $home $provider
      fi
    done
  done

  chown -Rf $user:nogroup $home/jobs/
}

