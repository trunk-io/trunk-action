#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
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
