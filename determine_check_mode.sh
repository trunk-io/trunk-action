#!/bin/bash

set -euo pipefail

check_mode="${INPUT_CHECK_MODE}"
if [[ -z ${check_mode} ]]; then
  if [[ ${GITHUB_EVENT_NAME} == "pull_request" || ${GITHUB_EVENT_NAME} == "pull_request_target" ]]; then
    check_mode="pull_request"
  elif [[ ${GITHUB_EVENT_NAME} == "push" ]]; then
    check_mode="push"
  else
    check_mode="all"
  fi
fi
echo "TRUNK_CHECK_MODE=${check_mode}" >>"${GITHUB_ENV}"
