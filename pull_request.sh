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

if [[ ${INPUT_GITHUB_REF_NAME} == "${GITHUB_EVENT_PULL_REQUEST_NUMBER}/merge" ]]; then
  # If we have checked out the merge commit then fetch enough history to use HEAD^1 as the upstream.
  # We use this instead of github.event.pull_request.base.sha which can be incorrect sometimes.
  head_sha=$(git rev-parse HEAD)
  fetch --depth=2 origin "${head_sha}"
  upstream=$(git rev-parse HEAD^1)
  git_commit=$(git rev-parse HEAD^2)
  echo "Detected merge commit, using HEAD^1 (${upstream}) as upstream and HEAD^2 (${git_commit}) as github commit"
fi

if [[ -z ${upstream+x} ]]; then
  echo "The 'upstream' variable is not defined or is empty."
else
  echo "The 'upstream' variable is defined and has a value."
fi

if [[ -z ${upstream+x} ]]; then
  # Otherwise use github.event.pull_request.base.sha as the upstream.
  echo "hi, i am in here"
  upstream="${GITHUB_EVENT_PULL_REQUEST_BASE_SHA}"
  echo "${GITHUB_EVENT_PULL_REQUEST_BASE_SHA}"
  echo "${upstream}"
  git_commit="${GITHUB_EVENT_PULL_REQUEST_HEAD_SHA}"
  fetch origin "${upstream}"
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

if [[ -n ${INPUT_AUTOFIX_AND_PUSH} ]]; then
  "${TRUNK_PATH}" check --ci --upstream "${upstream}" --fix
  git config --global user.email ""
  git config --global user.name "${GITHUB_ACTOR}"
  git diff-index --quiet HEAD --
  if git diff-index --quiet HEAD --; then
    git commit --allow-empty -m "No autofixes needed!"
  else
    git commit -a -m "Trunk check applied autofixes automatically"
  fi
  git push origin "${INPUT_GITHUB_REF_NAME}"
else
  "${TRUNK_PATH}" check \
    --ci \
    --upstream "${upstream}" \
    --github-commit "${git_commit}" \
    --github-label "${INPUT_LABEL}" \
    "${annotation_argument}" \
    ${INPUT_ARGUMENTS}
fi
