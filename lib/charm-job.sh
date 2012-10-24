#!/bin/bash

[ -f lib/ch-file.sh ] && . lib/ch-file.sh
[ -f lib/juju-provider-info.sh ] && . lib/juju-provider-info.sh

install_build_tools() {
  local user=$1
  local home=$2

  mkdir -p -m755 $home/bin
  install --mode=755 --owner=$user --group=nogroup files/get-last-build-number $home/bin/
  install --mode=755 --owner=$user --group=nogroup files/update-build-numbers $home/bin/
}

job_name_for_charm() {
  local charm_name=$1
  local provider=$2
  local series=$3
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
  local job_name=$(job_name_for_charm $charm_name $provider $release)
  local juju_env=""
  local API_TOKEN=$(get_api_token $home)
  local build_publisher_enabled=$(config-get build_publisher_enabled)
  local ircbot_enabled=$(config-get ircbot_enabled)
  mkdir -p -m755 $home/jobs/$job_name
  ch_template_file 755 \
                   $user:nogroup \
                   job-config.xml \
                   $home/jobs/$job_name/config.xml \
                   "user home provider charm_name job_name API_TOKEN build_publisher_enabled ircbot_enabled juju_env"
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

#update_charm_jobs() {
#  local user=$1
#  local home=$2
#
#  for charm_name in `su -l $user -c "charm list | grep lp:charms | sed 's/lp:charms\///'"`; do
#    for provider in `provider_types $home`; do
#      if blacklisted_charm $charm_name $provider ; then
#        juju-log "skipping blacklisted $charm_name for provider $provider"
#      else
#        create_job_for_charm $charm_name $user $home $provider
#      fi
#    done
#  done
#
#}

charm_name_from_branch() {
  local branch=$1
  echo $branch | sed 's/lp:charms\///'
}

list_contains() {
  local list=$1
  local element=$2

  for i in $list; do
    if [ $i == $element ]; then
      return 0
    fi
  done

  return 1
}

list_branches_to_test() {
  #raw_whitelist=`config-get charm_whitelist`
  #whitelist_charms=( $(IFS=',' echo ${raw_whitelist//[[:space:]]/}) )
  #if list_contains( ${whitelist_charms[@]}, "all" ); then
  #  charms_in_store=( $(su -l $user -c "charm list | grep lp:charms") )
  #fi
  #whitelist_charms=${whitelist_charms[@]//all/}
  #echo "${charms_in_store[@]}" "${whiltelist_charms[@]}"
  #charms_in_store=( $(su -l $user -c "charm list | grep lp:charms") )
  #echo "${charms_in_store[@]}"
  su -l jenkins -c "charm list | grep lp:charms"
}

list_charm_jobs() {
  local user=$1
  local home=$2

  ls $home/jobs
}

next_build_number() {
  local user=$1
  local home=$2
  local charm_job=$3

  local last_build=$($home/bin/get-last-build-number $charm_job || echo "0")
  $(( $last_build + 1 ))
}

update_build_numbers() {
  local user=$1
  local home=$2

  for job in $(list_charm_jobs $user $home); do
    juju-log "updating $home/jobs/$job/nextBuildNumber"
    echo $(next_build_number $user $home $job) > $home/jobs/$job/nextBuildNumber
  done
}

update_charm_jobs() {
  local user=$1
  local home=$2

  juju-log "installing jenkins build tools"
  install_build_tools $user $home

  for charm in $(list_branches_to_test); do
    local charm_name=$(charm_name_from_branch $charm)


    for provider in $(provider_types $home); do
      if blacklisted_charm $charm_name $provider ; then
        juju-log "skipping blacklisted $charm_name for provider $provider"
      else
        create_job_for_charm $charm_name $user $home $provider
      fi
    done
  done

  update_build_numbers $user $home

  chown -Rf $user:nogroup $home/jobs/

}
