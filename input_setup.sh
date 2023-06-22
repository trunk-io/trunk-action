#!/bin/bash

# shellcheck disable=SC2086,SC2310,SC2312

# SC2310: This function is invoked in an 'if' condition so set -e will be disabled.
#         Invoke separately if failures should cause the script to exit.
#
# SC2312: Consider invoking this command separately to avoid masking its return value (or use '|| true' to ignore).

set -euo pipefail

inputs() {
  # quoted here because of non-legal names (e.g. check-mode - the "-" gets parsed as subtraction)
  jq -r ".[\"$1\"] // empty" <<<${SETUP_INPUTS}
}

payload() {
  jq -r ".inputs.payload | fromjson | .$1 // empty" ${GITHUB_EVENT_PATH}
}

githubEventPR() {
  jq -r ".$1 // empty" <<<${SETUP_GITHUB_EVENT_PR}
}

# This is different from the other scripts because the INPUT_DEBUG variable doesn't exist yet
if [[ $(inputs debug) == "true" || $(payload debug) == "true" ]]; then
  set -x
fi

# this seems like a no-op?
cat >>${GITHUB_ENV} <<EOF
GITHUB_TOKEN=${SETUP_GITHUB_TOKEN}
EOF

# Every inputs.field should be referenced as INPUT_FIELD later in the action. This allows
# the field to be set either as an argument to the github action or via inputs.json.
if [[ "$(inputs check-mode)" == "payload" ]]; then

  INPUT_GITHUB_TOKEN=$(payload githubToken)
  INPUT_TRUNK_TOKEN=$(payload trunkToken)
  echo "::add-mask::${INPUT_GITHUB_TOKEN}"
  echo "::add-mask::${INPUT_TRUNK_TOKEN}"

  cat >>${GITHUB_ENV} <<EOF
INPUT_GITHUB_TOKEN=${INPUT_GITHUB_TOKEN}
INPUT_TRUNK_TOKEN=${INPUT_TRUNK_TOKEN}
TRUNK_TOKEN=${INPUT_TRUNK_TOKEN}
GITHUB_EVENT_PULL_REQUEST_BASE_REPO_OWNER=$(payload pullRequest.base.repo.owner.login)
GITHUB_EVENT_PULL_REQUEST_BASE_REPO_NAME=$(payload pullRequest.base.repo.name)
GITHUB_EVENT_PULL_REQUEST_BASE_SHA=$(payload pullRequest.base.sha)
GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK=$(payload pullRequest.head.repo.fork)
GITHUB_EVENT_PULL_REQUEST_HEAD_SHA=$(payload pullRequest.head.sha)
GITHUB_EVENT_PULL_REQUEST_NUMBER=$(payload pullRequest.number)
INPUT_ARGUMENTS=$(payload arguments)
INPUT_CACHE=$(payload cache)
INPUT_CACHE_KEY=$(payload cacheKey)
INPUT_CACHE_PATH=$(payload cachePath)
INPUT_CHECK_ALL_MODE=$(payload checkAllMode)
INPUT_CHECK_MODE=$(payload checkMode)
INPUT_CHECK_RUN_ID=$(payload checkRunId)
INPUT_DEBUG=$(payload debug)
INPUT_GITHUB_REF_NAME=$(payload targetRefName)
INPUT_LABEL=$(payload label)
INPUT_SETUP_CACHE_KEY=$(payload setupCacheKey)
INPUT_SETUP_DEPS=$(payload setupDeps)
INPUT_TARGET_CHECKOUT=$(payload targetCheckout)
INPUT_TARGET_CHECKOUT_REF=$(payload targetCheckoutRef)
INPUT_TRUNK_PATH=$(payload trunkPath)
INPUT_UPLOAD_LANDING_STATE=$(payload uploadLandingState)
INPUT_UPLOAD_SERIES=$(payload uploadSeries)
EOF

else

  INPUT_GITHUB_TOKEN=$(inputs github-token)
  INPUT_TRUNK_TOKEN=$(inputs trunk-token)
  echo "::add-mask::${INPUT_GITHUB_TOKEN}"
  echo "::add-mask::${INPUT_TRUNK_TOKEN}"

  cat >>${GITHUB_ENV} <<EOF
INPUT_GITHUB_TOKEN=${INPUT_GITHUB_TOKEN}
INPUT_TRUNK_TOKEN=${INPUT_TRUNK_TOKEN}
TRUNK_TOKEN=${INPUT_TRUNK_TOKEN}
GITHUB_EVENT_PULL_REQUEST_BASE_SHA=$(githubEventPR base.sha)
GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK=$(githubEventPR head.repo.fork)
GITHUB_EVENT_PULL_REQUEST_HEAD_SHA=$(githubEventPR head.sha)
GITHUB_EVENT_PULL_REQUEST_NUMBER=$(githubEventPR number)
GITHUB_REF_NAME=${SETUP_GITHUB_REF_NAME}
INPUT_ARGUMENTS=$(inputs arguments)
INPUT_CACHE=$(inputs cache)
INPUT_CACHE_KEY=trunk-$(inputs cache-key)-${SETUP_RUNNER_OS}-${SETUP_FILE_HASH}
INPUT_CACHE_PATH=~/.cache/trunk
INPUT_CHECK_ALL_MODE=$(inputs check-all-mode)
INPUT_CHECK_MODE=$(inputs check-mode)
INPUT_CHECK_RUN_ID=$(inputs check-run-id)
INPUT_DEBUG=$(inputs debug)
INPUT_GITHUB_REF_NAME=${SETUP_GITHUB_REF_NAME}
INPUT_SETUP_DEPS=$(inputs setup-deps)
INPUT_TARGET_CHECKOUT=
INPUT_TARGET_CHECKOUT_REF=
INPUT_LABEL=$(inputs label)
INPUT_SETUP_CACHE_KEY=$(inputs cache-key)
INPUT_TRUNK_PATH=$(inputs trunk-path)
INPUT_UPLOAD_LANDING_STATE=false
INPUT_UPLOAD_SERIES=$(inputs upload-series)
EOF

fi
