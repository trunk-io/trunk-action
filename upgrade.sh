#!/bin/bash

set -euo pipefail

echo "RUNNING THE COMMAND <${TRUNK_PATH} upgrade -n ${UPGRADE_ARGUMENTS}>"
# trunk-ignore(shellcheck/SC2086): pass arguments directly as is
upgrade_output=$(${TRUNK_PATH} upgrade -n ${UPGRADE_ARGUMENTS})
new_cli_version=$(echo "${upgrade_output}" | grep "cli upgrade" | awk '{print $NF}' | sed -e 's/\x1b\[[0-9;]*m//g')
title_message="Upgrade trunk"

if [[ -n ${new_cli_version} ]]; then
  title_message="Upgrade trunk to ${new_cli_version}"
fi

echo "UPGRADE_OUTPUT=${upgrade_output}" >>"$GITHUB_OUTPUT"
echo "TITLE_MESSAGE=${title_message}" >>"$GITHUB_OUTPUT"
