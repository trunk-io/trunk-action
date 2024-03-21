#!/bin/bash

set -euo pipefail

if [[ ${INPUT_DEBUG:-false} == "true" ]]; then
  set -x
fi

tmpdir="$(mktemp -d)"
echo "TRUNK_TMPDIR=${tmpdir}" >>"${GITHUB_ENV}"

curl -fsSL https://trunk.io/releases/trunk -o "${tmpdir}/trunk"
chmod u+x "${tmpdir}/trunk"
trunk_path="${tmpdir}/trunk"

echo "TRUNK_PATH=${trunk_path}" >>"${GITHUB_ENV}"
echo ${tmpdir} >>$GITHUB_PATH

# Ensure that trunk CLI is downloaded before subsequent steps (swallow output of version command)
(${trunk_path} version >/dev/null 2>&1) || echo "::warning::${trunk_path} does not exist!"
