#!/usr/bin/env python3

import json
import os
import sys

def main(github_env_path, repo_test_name, repo_test_description):
  try:
    landing_state = json.load(open('/tmp/landing-state.json'))
  except FileNotFoundError as e:
    print("Failed to open /tmp/landing-state.json - did `trunk check` run?")
    sys.exit(1)
    return

  lint_action_count = len(landing_state.get("lintActions", []))
  task_failure_count = len(landing_state.get("taskFailures", []))

  print("::group::.trunk/trunk.yaml")
  print(open(".trunk/trunk.yaml").read())
  print("::endgroup::")

  with open(github_env_path, 'a') as env:
    env.write('landing_state_artifact_name=')
    env.write(f'{repo_test_name.replace("/", " ")} ({repo_test_description})')
    env.write('\n')

  print(f'lint_action_count={lint_action_count}')
  print(f'task_failure_count={task_failure_count}')

  if lint_action_count == 0:
    print("No lint actions were run - something went wrong.")
    sys.exit(1)

  if task_failure_count > 0:
    print('Failures can be viewed in the logs for the previous step')
    sys.exit(1)

  print("No task failures!")

if __name__ == '__main__':
  main(sys.argv[1], sys.argv[2], sys.argv[3])
