#!/bin/bash

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

check_mode="${INPUT_CHECK_MODE}"
if [[ -z ${check_mode} ]]; then
  if [[ ${GITHUB_EVENT_NAME} == "pull_request" || ${GITHUB_EVENT_NAME} == "pull_request_target" ]]; then
    check_mode="pull_request"
  elif [[ ${GITHUB_EVENT_NAME} == "push" && ${GITHUB_REF_NAME} == trunk-merge/* ]]; then
    check_mode="trunk_merge"
  elif [[ ${GITHUB_EVENT_NAME} == "push" ]]; then
    check_mode="push"
  elif [[ ${GITHUB_EVENT_NAME} == "workflow_dispatch" && (${GITHUB_REF_NAME} == trunk-merge/* || ${GITHUB_REF_NAME} == trunk-merge-beta/*) ]]; then
    check_mode="trunk_merge"
  elif [[ ${GITHUB_EVENT_NAME} == "workflow_dispatch" || ${GITHUB_EVENT_NAME} == "schedule" ]]; then
    check_mode="all"
  else
    check_mode="none"
  fi
elif [[ ${check_mode} != "all" && ${check_mode} != "none" && ${check_mode} != "populate_cache_only" && ${check_mode} != "pull_request" && ${check_mode} != "push" && ${check_mode} != "trunk_merge" ]]; then
  echo "check-mode must be one of: 'all', 'none', 'populate_cache_only', 'pull_request', 'push', or 'trunk_merge'"
  exit 1
fi

echo "TRUNK_CHECK_MODE=${check_mode}" >>"${GITHUB_ENV}"
