#!/bin/bash

juju_environment_variable_for() {
  local home=$1
  local key=$2
  
  local environments_file="$home/.juju/environments.yaml"
  [ -f $environments_file ] && cat $environments_file | awk '/\ $key:\ / { print $2 }' || echo ""
}

environment_releases() {
  local home=$1
  local environments_file="$home/.juju/environments.yaml"
  [ -f $environments_file ] && cat $environments_file | awk '/\ default-series:\ / { print $2 }' || echo ""
}

releases() {
  ( environment_releases $home; lsb_release -cs ) | sort | uniq
}

has_release() {
  local home=$1
  local release=$2
  for configured_release in `environment_releases $home`; do
    if [ $release == $configured_release ]; then
      return 0
    fi
  done
  return 1
}

provider_types() {
  local home=$1
  local environments_file="$home/.juju/environments.yaml"
  [ -f $environments_file ] && cat $environments_file | awk '/\ type:\ / { print $2 }' || echo ""
}

has_provider() {
  local home=$1
  local provider=$2
  for configured_provider in `provider_types $home`; do
    if [ $provider == $configured_provider ]; then
      return 0
    fi
  done
  return 1
}

