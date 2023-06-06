#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

upstream=$(git rev-parse HEAD^1)
git_commit=$(git rev-parse HEAD^2)
echo "Detected merge queue commit, using HEAD^1 (${upstream}) as upstream and HEAD^2 (${git_commit}) as github commit"

if [[ -n ${INPUT_CHECK_RUN_ID} ]]; then
  annotation_argument=--trunk-annotate=${INPUT_CHECK_RUN_ID}
else
  annotation_argument=""
fi


if [[ -n ${INPUT_TRUNK_TOKEN} ]]; then
  "${TRUNK_PATH}" check \
    --ci \
    --upstream "${upstream}" \
    --github-commit "${git_commit}" \
    --github-label "${INPUT_LABEL}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    "${annotation_argument}" \
    ${INPUT_ARGUMENTS}
else
  "${TRUNK_PATH}" check \
    --ci \
    --upstream "${upstream}" \
    --github-commit "${git_commit}" \
    --github-label "${INPUT_LABEL}" \
    "${annotation_argument}" \
    ${INPUT_ARGUMENTS}
fi
