#!/bin/bash

set -euo pipefail

# trunk-ignore(shellcheck/SC2086): pass arguments directly as is
upgrade_output=$(${TRUNK_PATH} upgrade --no-progress -n ${UPGRADE_ARGUMENTS} | sed -e 's/\x1b\[[0-9;]*m//g' | grep "upgrade" -A 500)
new_cli_version=$(echo "${upgrade_output}" | grep "cli upgrade" | awk '{print $NF}')
title_message="Upgrade trunk"

if [[ -n ${new_cli_version} ]]; then
  title_message="Upgrade trunk to ${new_cli_version}"
fi

# TODO: TYLER ADD AN EXPLANATION COMMENT
if [[ ! -e trunk ]]; then
  ${TRUNK_PATH} daemon shutdown
  git config --unset core.hooksPath
  rm -f .trunk/landing-state.json
fi

# trunk-ignore(shellcheck/SC2001)
formatted_output=$(echo "${upgrade_output}" | sed -e 's/^\(  \)/*\1$/')
# TODO: TYLER FIGURE THIS OUT
# formatted_output=${upgrade_output//^\( +\)/*\1$}
# TODO: TYLER CHANGE URL
banner="[![Trunk](https://raw.githubusercontent.com/TylerJang27/trunk-action/tyler/upgrade-mode/trunk_banner.png)](https://trunk.io)"

# TODO: TYLER MAKE THIS A TEMPLATE AND INSERT IT
description="${banner}\n\n${formatted_output}"

# TODO: TYLER REMOVE THIS
echo "Finished running upgrade"
echo "${description}" >foo5.md

# TODO: TYLER ATTEMPT TO CLEAN THIS UP
# trunk-ignore(shellcheck/SC2129): Write multi-line value to output
echo "DESCRIPTION<<EOF" >>"${GITHUB_OUTPUT}"
echo "${description}" >>"${GITHUB_OUTPUT}"
echo "EOF" >>"${GITHUB_OUTPUT}"

echo "TITLE_MESSAGE=${title_message}" >>"${GITHUB_OUTPUT}"
