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

pwd

if [[ ${INPUT_GITHUB_REF_NAME} == "${GITHUB_EVENT_PULL_REQUEST_NUMBER}/merge" ]]; then
  # If we have checked out the merge commit then fetch enough history to use HEAD^1 as the upstream.
  # We use this instead of github.event.pull_request.base.sha which can be incorrect sometimes.
  head_sha=$(git rev-parse HEAD)
  if [[ ! -e ${TEST_GITHUB_EVENT_PATH} ]]; then
    fetch --depth=2 origin "${head_sha}"
  fi
  upstream=$(git rev-parse HEAD^1)
  git_commit=$(git rev-parse HEAD^2)
  echo "Detected merge commit, using HEAD^1 (${upstream}) as upstream and HEAD^2 (${git_commit}) as github commit"
fi

if [[ -z ${upstream+x} ]]; then
  # Otherwise use github.event.pull_request.base.sha as the upstream.
  upstream="${GITHUB_EVENT_PULL_REQUEST_BASE_SHA}"
  git_commit="${GITHUB_EVENT_PULL_REQUEST_HEAD_SHA}"
  if [[ ! -e ${TEST_GITHUB_EVENT_PATH} ]]; then
    fetch origin "${upstream}"
  fi
fi

save_annotations=${INPUT_SAVE_ANNOTATIONS}
if [[ ${save_annotations} == "auto" && ${GITHUB_EVENT_PULL_REQUEST_HEAD_REPO_FORK} == "true" ]]; then
  echo "Fork detected, saving annotations to an artifact."
  save_annotations=true
fi

if [[ -n ${INPUT_CHECK_RUN_ID} ]]; then
  annotation_argument=--trunk-annotate=${INPUT_CHECK_RUN_ID}
elif [[ ${save_annotations} == "true" ]]; then
  annotation_argument=--github-annotate-file=${TRUNK_TMPDIR}/annotations.bin
  # Signal that we need to upload an annotations artifact
  echo "TRUNK_UPLOAD_ANNOTATIONS=true" >>"${GITHUB_ENV}"
else
  annotation_argument=--github-annotate
fi

"${TRUNK_PATH}" check \
  --ci \
  --upstream "${upstream}" \
  --github-commit "${git_commit}" \
  --github-label "${INPUT_LABEL}" \
  "${annotation_argument}" \
  ${INPUT_ARGUMENTS}
