#!/bin/bash

set -euo pipefail

echo "RUNNING THE COMMAND <${TRUNK_PATH} upgrade --no-progress -n ${UPGRADE_ARGUMENTS}>"
# trunk-ignore(shellcheck/SC2086): pass arguments directly as is
upgrade_output=$(${TRUNK_PATH} upgrade --no-progress -n ${UPGRADE_ARGUMENTS})
# TODO: TYLER TRIM THE OUTPUT FOR AN INSTALL
new_cli_version=$(echo "${upgrade_output}" | grep "cli upgrade" | awk '{print $NF}' | sed -e 's/\x1b\[[0-9;]*m//g')
title_message="Upgrade trunk"

if [[ -n ${new_cli_version} ]]; then
  title_message="Upgrade trunk to ${new_cli_version}"
fi

if [ ! -e trunk ]; then
  ln -s "${TRUNK_PATH}" trunk
  export PATH="${PATH}:${TRUNK_PATH}"
fi

echo "Finished running upgrade"

# echo "UPGRADE_OUTPUT=${upgrade_output}" >>"$GITHUB_OUTPUT"
# trunk-ignore(shellcheck/SC2129)
echo "UPGRADE_OUTPUT<<EOF" >>"$GITHUB_OUTPUT"
echo "${upgrade_output}" >>"$GITHUB_OUTPUT"
echo "EOF" >>"$GITHUB_OUTPUT"

echo "TITLE_MESSAGE=${title_message}" >>"$GITHUB_OUTPUT"
