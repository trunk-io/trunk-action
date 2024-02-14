#!/bin/bash

set -euo pipefail

if [[ ${INPUT_DEBUG:-false} == "true" ]]; then
  set -x
fi

tmpdir="$(mktemp -d)"
echo "TRUNK_TMPDIR=${tmpdir}" >>"${GITHUB_ENV}"

trunk_path="${INPUT_TRUNK_PATH}"
if [[ -z ${trunk_path} ]]; then
  if [[ -f .trunk/bin/trunk && -x .trunk/bin/trunk ]]; then
    trunk_path=.trunk/bin/trunk
  elif [[ -f tools/trunk && -x tools/trunk ]]; then
    trunk_path=tools/trunk
  elif [[ -f trunk && -x trunk ]]; then
    trunk_path=./trunk
  else
    curl -fsSL https://trunk.io/releases/trunk -o "${tmpdir}/trunk"
    chmod u+x "${tmpdir}/trunk"
    trunk_path="${tmpdir}/trunk"
  fi
fi
echo "TRUNK_PATH=${trunk_path}" >>"${GITHUB_ENV}"
# Ensure that trunk CLI is downloaded before subsequent steps
${trunk_path} version || echo "::warning::${trunk_path} does not exist!"
