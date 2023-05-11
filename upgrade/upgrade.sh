#!/bin/bash

set -euo pipefail

# Step 1: Run upgrade and strip ANSI coloring.
# trunk-ignore(shellcheck/SC2086): pass arguments directly as is
upgrade_output=$(${TRUNK_PATH} upgrade --no-progress -n ${UPGRADE_ARGUMENTS} | sed -e 's/\x1b\[[0-9;]*m//g')

# Step 2a: Parse output. If up to date, exit successfully.
if [[ ${upgrade_output} == *"Already up to date"* ]]; then
  echo "Already up to date."
  exit 0
fi

# Step 2b: Parse output. Strip launcher downloading messages and parse cli upgrade if present.
trimmed_upgrade_output=$(echo "${upgrade_output}" | grep "upgrade" -A 500)
title_message="Upgrade trunk"

if [[ ${trimmed_upgrade_output} == *"cli upgrade"* ]]; then
  new_cli_version=$(echo "${trimmed_upgrade_output}" | grep "cli upgrade" | awk '{print $NF}')
  title_message="Upgrade trunk to ${new_cli_version}"
fi

# Step 3: Prepare for pull request creation action.
# Avoid triggering a git-hook, and avoid resetting git hook config via daemon
${TRUNK_PATH} daemon shutdown
git config --local --unset core.hooksPath || true
rm -f .trunk/landing-state.json

# Step 4: Format upgrade output for PR.
# Replace space indentation with bulleted list (including sub-bullets)
# trunk-ignore(shellcheck/SC2001): more complicated sed parsing required
formatted_output=$(echo "${trimmed_upgrade_output}" | sed -e 's/^\(  \)\{0,1\}  /\1- /')

# Step 5: Generate markdown
description=$(echo "${formatted_output}" | sed -e '/^UPGRADE_CONTENTS/{
r /dev/stdin
d
}' "${GITHUB_ACTION_PATH}"/upgrade_pr.md)

# Step 6: Write outputs
cat >>"${GITHUB_ENV}" <<EOF
PR_DESCRIPTION="${description}"
PR_TITLE="${title_message}"
EOF
