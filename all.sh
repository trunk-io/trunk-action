#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

if [[ -z ${INPUT_TRUNK_TOKEN} ]]; then
  "${TRUNK_PATH}" check \
    --ci \
    --all \
    --output-file .trunk/landing-state.json \
    --github-commit "${GITHUB_SHA}" \
    ${INPUT_ARGUMENTS}
elif [[ ${INPUT_CHECK_ALL_MODE} == "hold-the-line" ]]; then
  prev_ref="$("${TRUNK_PATH}" check get-latest-raw-output \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    "${latest_raw_upload}")"
  if [[ ${prev_ref} =~ .*UNSPECIFIED.* ]]; then
    echo "${prev_ref}"
    htl_arg=""
  else
    htl_arg="--htl-factories-path=${latest_raw_upload}"
    git fetch origin "${prev_ref}"
  fi
  "${TRUNK_PATH}" check \
    --all \
    --upload \
    ${htl_arg} \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
else
  "${TRUNK_PATH}" check \
    --all \
    --output-file .trunk/landing-state.json \
    --upload \
    --series "${INPUT_UPLOAD_SERIES:-${INPUT_GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
fi
