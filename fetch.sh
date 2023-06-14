#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

fetch() {
  git -c protocol.version=2 fetch -q \
    --no-tags \
    --no-recurse-submodules \
    "$@"
}

if [[ ${TRUNK_CHECK_MODE} == "all" ]]; then
  if [[ -n ${INPUT_TRUNK_TOKEN} && ${INPUT_CHECK_ALL_MODE} == "hold-the-line" ]]; then
    latest_raw_upload="$(mktemp)"
    # Note: the order of these if clauses is important. We can't invert them using if ! because that
    # would cause the exit code of prev_ref=$(...) to get discarded
    if prev_ref="$("${TRUNK_PATH}" check get-latest-raw-output --debug --log-level=trace\
      --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
      --token "${INPUT_TRUNK_TOKEN}" \
      "${latest_raw_upload}")"; then
      if [[ ${prev_ref} =~ .*UNSPECIFIED.* ]]; then
        echo "TRUNK_CHECK_ALL_HTL_ARG=" >>"${GITHUB_ENV}"
      else
        echo "TRUNK_CHECK_ALL_HTL_ARG=--htl-factories-path=${latest_raw_upload}" >>"${GITHUB_ENV}"
        git fetch origin "${prev_ref}"
      fi
    else
      exit_code=$?
      # In this situation. $prev_ref is actually the error message, because we use stderr incorrectly
      echo -n "${prev_ref}"
      exit "${exit_code}"
    fi
  fi
elif [[ ${TRUNK_CHECK_MODE} == "pull_request" ]]; then
  if [[ ${INPUT_GITHUB_REF_NAME} == "${GITHUB_EVENT_PULL_REQUEST_NUMBER}/merge" ]]; then
    # If we have checked out the merge commit then fetch enough history to use HEAD^1 as the upstream.
    # We use this instead of github.event.pull_request.base.sha which can be incorrect sometimes.
    head_sha=$(git rev-parse HEAD)
    fetch --depth=2 origin "${head_sha}"
  fi

  if [[ -z ${upstream+x} ]]; then
    # Otherwise use github.event.pull_request.base.sha as the upstream.
    upstream="${GITHUB_EVENT_PULL_REQUEST_BASE_SHA}"
    fetch origin "${upstream}"
  fi
elif [[ ${TRUNK_CHECK_MODE} == "push" ]]; then
  if [[ ${GITHUB_REF_NAME} == gh-readonly-queue/* ]]; then
    # If we are running via the GH merge queue then we use HEAD^1 as the commit as github.event.before will be inaccurate.
    head_sha=$(git rev-parse HEAD)
    fetch --depth=2 origin "${head_sha}"
  fi

  if [[ -z ${upstream+x} ]]; then
    # Otherwise use github.event.before as the upstream.
    upstream="${GITHUB_EVENT_BEFORE}"
    fetch origin "${upstream}"
  fi
elif [[ ${TRUNK_CHECK_MODE} == "trunk_merge" ]]; then
  head_sha=$(git rev-parse HEAD)
  fetch --depth=2 origin "${head_sha}"
fi
