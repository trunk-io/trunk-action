#!/bin/bash

# shellcheck disable=SC2086,SC2310

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

payload() {
  jq '.inputs.payload | fromjson | .$@ // empty' ${GITHUB_EVENT_PATH}
}

inputs() {
  jq '.$@ // empty' <<<${SETUP_INPUTS}
}

githubEventPR() {
  jq '.$@ // empty' <<<${SETUP_GITHUB_EVENT_PR}
}

# this seems like a no-op?
cat >>${GITHUB_ENV} <<EOF
GITHUB_TOKEN=${SETUP_GITHUB_TOKEN}
EOF

# Every inputs.field should be referenced as INPUT_FIELD later in the action. This allows
# the field to be set either as an argument to the github action or via inputs.json.
if [[ "$(inputs check-mode || true)" == "payload" ]]; then

  INPUT_GITHUB_TOKEN=$(payload githubToken || true)
  INPUT_TRUNK_TOKEN=$(payload trunkToken || true)
  echo "::add-mask::${INPUT_GITHUB_TOKEN}"
  echo "::add-mask::${INPUT_TRUNK_TOKEN}"

  cat >>${GITHUB_ENV} <<EOF
INPUT_GITHUB_TOKEN=${INPUT_GITHUB_TOKEN}
INPUT_TRUNK_TOKEN=${INPUT_TRUNK_TOKEN}
TRUNK_TOKEN=${INPUT_TRUNK_TOKEN}
GITHUB_EVENT_PULL_REQUEST_BASE_REPO_OWNER=$(payload pullRequest.base.repo.owner.login || true)
GITHUB_EVENT_PULL_REQUEST_BASE_REPO_NAME=$(payload pullRequest.base.repo.name || true)
GITHUB_EVENT_PULL_REQUEST_BASE_SHA=$(payload pullRequest.base.sha || true)
GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK=$(payload pullRequest.head.repo.fork || true)
GITHUB_EVENT_PULL_REQUEST_HEAD_SHA=$(payload pullRequest.head.sha || true)
GITHUB_EVENT_PULL_REQUEST_NUMBER=$(payload pullRequest.number || true)
INPUT_ARGUMENTS=$(payload arguments || true)
INPUT_CACHE=$(payload cache || true)
INPUT_CACHE_KEY=$(payload cacheKey || true)
INPUT_CACHE_PATH=$(payload cachePath || true)
INPUT_CHECK_ALL_MODE=$(payload checkAllMode || true)
INPUT_CHECK_MODE=$(payload checkMode || true)
INPUT_CHECK_RUN_ID=$(payload checkRunId || true)
INPUT_DEBUG=$(payload debug || true)
INPUT_GITHUB_REF_NAME=$(payload targetRefName || true)
INPUT_LABEL=$(payload label || true)
INPUT_SETUP_CACHE_KEY=$(payload setupCacheKey || true)
INPUT_SETUP_DEPS=$(payload setupDeps || true)
INPUT_TARGET_CHECKOUT=$(payload targetCheckout || true)
INPUT_TARGET_CHECKOUT_REF=$(payload targetCheckoutRef || true)
INPUT_TRUNK_PATH=$(payload trunkPath || true)
INPUT_UPLOAD_LANDING_STATE=$(payload uploadLandingState || true)
INPUT_UPLOAD_SERIES=$(payload uploadSeries || true)
EOF

else

  INPUT_GITHUB_TOKEN=$(inputs github-token || true)
  INPUT_TRUNK_TOKEN=$(inputs trunk-token || true)
  echo "::add-mask::${INPUT_GITHUB_TOKEN}"
  echo "::add-mask::${INPUT_TRUNK_TOKEN}"

  cat >>${GITHUB_ENV} <<EOF
INPUT_GITHUB_TOKEN=${INPUT_GITHUB_TOKEN}
INPUT_TRUNK_TOKEN=${INPUT_TRUNK_TOKEN}
TRUNK_TOKEN=${INPUT_TRUNK_TOKEN}
GITHUB_EVENT_PULL_REQUEST_BASE_SHA=$(githubEventPR pull_request.base.sha || true)
GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK=$(githubEventPR pull_request.head.repo.fork || true)
GITHUB_EVENT_PULL_REQUEST_HEAD_SHA=$(githubEventPR pull_request.head.sha || true)
GITHUB_EVENT_PULL_REQUEST_NUMBER=$(githubEventPR pull_request.number || true)
GITHUB_REF_NAME=${SETUP_GITHUB_REF_NAME}
INPUT_ARGUMENTS=$(inputs arguments || true)
INPUT_CACHE=$(inputs cache || true)
INPUT_CACHE_KEY=trunk-$(inputs cache-key || true)-${SETUP_RUNNER_OS}-${SETUP_FILE_HASH}
INPUT_CACHE_PATH=~/.cache/trunk
INPUT_CHECK_ALL_MODE=$(inputs check-all-mode || true)
INPUT_CHECK_MODE=$(inputs check-mode || true)
INPUT_CHECK_RUN_ID=$(inputs check-run-id || true)
INPUT_DEBUG=$(inputs debug || true)
INPUT_GITHUB_REF_NAME=${SETUP_GITHUB_REF_NAME}
INPUT_SETUP_DEPS=$(inputs setup-deps || true)
INPUT_TARGET_CHECKOUT=
INPUT_TARGET_CHECKOUT_REF=
INPUT_LABEL=$(inputs label || true)
INPUT_SETUP_CACHE_KEY=$(inputs cache-key || true)
INPUT_TRUNK_PATH=$(inputs trunk-path || true)
INPUT_UPLOAD_LANDING_STATE=false
INPUT_UPLOAD_SERIES=$(inputs upload-series || true)
EOF

fi
