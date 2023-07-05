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

if [[ -z ${INPUT_TRUNK_TOKEN} ]]; then
  "${TRUNK_PATH}" check \
    --ci \
    --all \
    --github-commit "${GITHUB_SHA}" \
    ${INPUT_ARGUMENTS}
elif [[ ${INPUT_CHECK_ALL_MODE} == "hold-the-line" ]]; then
  latest_raw_upload="$(mktemp)"
  prev_ref="$("${TRUNK_PATH}" check get-latest-raw-output \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    "${latest_raw_upload}")"
  if [[ ${prev_ref} =~ .*UNSPECIFIED.* ]]; then
    echo "${prev_ref}"
    htl_arg=""
  else
    htl_arg="--htl-factories-path=${latest_raw_upload}"
    fetch origin "${prev_ref}"
  fi
  if [[ -n ${INPUT_UPLOAD_ID} ]]; then
    upload_id_arg="--upload-id ${INPUT_UPLOAD_ID}"
  else
    upload_id_arg=""
  fi
  "${TRUNK_PATH}" check \
    --all \
    --upload \
    ${htl_arg} \
    ${upload_id_arg} \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
else
  "${TRUNK_PATH}" check \
    --all \
    --upload \
    --series "${INPUT_UPLOAD_SERIES:-${INPUT_GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
fi
