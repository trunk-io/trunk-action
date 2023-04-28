#!/bin/bash

# shellcheck disable=SC2086

set -euo pipefail

if [[ ${INPUT_DEBUG} == "true" ]]; then
  set -x
fi

TRUNK_VERSION=$("${TRUNK_PATH}" --version)
MINIMUM_CI_VERSION="1.8.2-beta.12"

# trunk-ignore-begin(shellcheck/SC2312): the == will fail if anything inside the $() fails
if [[ "$(printf "%s\n%s\n" "${MINIMUM_CI_VERSION}" "${TRUNK_VERSION}" |
  sort --version-sort |
  head -n 1)" == "${MINIMUM_CI_VERSION}"* ]] || [[ ${TRUNK_VERSION} == "0.0.0" ]]; then
  CI_ARGUMENT="--ci "
else
  CI_ARGUMENT=""
fi
# trunk-ignore-end(shellcheck/SC2312)

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
    git fetch origin "${prev_ref}"
  fi
  "${TRUNK_PATH}" check \
    ${CI_ARGUMENT} \
    --all \
    --upload \
    ${htl_arg} \
    --series "${INPUT_UPLOAD_SERIES:-${GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
else
  "${TRUNK_PATH}" check \
    ${CI_ARGUMENT} \
    --all \
    --upload \
    --series "${INPUT_UPLOAD_SERIES:-${INPUT_GITHUB_REF_NAME}}" \
    --token "${INPUT_TRUNK_TOKEN}" \
    ${INPUT_ARGUMENTS}
fi
