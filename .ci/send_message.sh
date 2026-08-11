#!/bin/bash
set -e

source ./.ci/util.sh

case $1 in

# Gets the message to send to the PR comment
# If MSG is empty (failure case), it fetches job failure information from GitHub API
# If MSG is provided (success case), it uses that message directly
get-message)
  checkForVariable "GITHUB_TOKEN"
  mkdir -p .ci-temp

  if [ -z "$MSG" ]; then
    JOBS_LINK="https://github.com/checkstyle/checkstyle/actions/runs/${GITHUB_RUN_ID}"
    API_LINK="https://api.github.com/repos/checkstyle/checkstyle/actions/runs/"
    API_LINK="${API_LINK}${GITHUB_RUN_ID}/jobs"
    echo "API_LINK=${API_LINK}"

    curl --fail-with-body -X GET "${API_LINK}" \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: token $GITHUB_TOKEN" \
      -o .ci-temp/info.json

    jq '.jobs' .ci-temp/info.json > ".ci-temp/jobs"
    jq '.[] | select(.conclusion == "failure") | .name' .ci-temp/jobs > .ci-temp/job_name
    jq '.[] | select(.conclusion == "failure") | .steps' .ci-temp/jobs > .ci-temp/steps
    jq '.[] | select(.conclusion == "failure") | .name' .ci-temp/steps > .ci-temp/step_name

    if [ -n "$FAILURE_PREFIX" ]; then
      echo "${FAILURE_PREFIX} failed on phase $(cat .ci-temp/job_name)," > .ci-temp/message
    else
      echo "Job failed on phase $(cat .ci-temp/job_name)," > .ci-temp/message
    fi
    echo "step $(cat .ci-temp/step_name).<br>Link: $JOBS_LINK" >> .ci-temp/message
  else
    echo "$MSG" > .ci-temp/message
  fi
  
  if [ -n "$GITHUB_OUTPUT" ]; then
    ./.ci/append-to-github-output.sh "message" "$(cat .ci-temp/message)"
  else
    echo "message=$(cat .ci-temp/message)"
  fi
  ;;

*)
  echo "Unexpected argument: $1"
  sleep 5s
  false
  ;;

esac
