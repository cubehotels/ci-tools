#!/bin/bash

# skip pull requests by renovate bot
echo "GITHUB_PULL_REQUEST_BRANCH: $GIT_BRANCH"
if [[ $GIT_BRANCH = renovate/* ]]; then
  echo 'skipping renovate bot PR'
  exit 0
fi

COMMIT_HASH=$(git rev-parse --short "$GITHUB_SHA")
DOCKER_IMAGE=$GITHUB_REPOSITORY
DOCKER_DEV_TAG=$([ "$GIT_BRANCH" == "master" ] || echo "-dev")
DOCKER_TAG=${BUILD_NUMBER}-${COMMIT_HASH}${DOCKER_DEV_TAG}
DOCKER_LATEST_TAG=latest${DOCKER_DEV_TAG}

COMMIT_RANGE="${LAST_BUILD_HASH}...${GITHUB_SHA}"

AUTHOR="$(git log -1 $GITHUB_SHA --pretty="%aN")"
BUILD_URL=https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}
COMPARE_URL=https://github.com/${GITHUB_REPOSITORY}/compare/${COMMIT_RANGE}
GITHUB_COMMIT_MESSAGE="$(git log ${COMMIT_RANGE} --pretty='- *%s*')"
GITHUB_COMMIT_MESSAGE_NL=${GITHUB_COMMIT_MESSAGE//
/\\\n} # \n (newline)

POSITIVE_EMOJI=(":the_horns:" ":ok_hand:" ":raised_hands:" ":sunglasses:" ":slightly_smiling_face:" ":relieved:" ":rocket:" ":tada:" ":+1:" ":muscle:" ":balloon:")
NEGATIVE_EMOJI=(":scream:" ":hankey:" ":bomb:" ":cry:" ":sob:" ":tired_face:" ":face_with_head_bandage:" ":skull_and_crossbones:" ":see_no_evil:" ":biohazard_sign:" ":warning:" ":fire:" ":rain_cloud:" ":radioactive_sign:" ":hurtrealbad:")
RANDOM=$$$(date +%s)

if [ "$JOB_STATUS" = "success" ]; then
  EMOJI=${POSITIVE_EMOJI[$RANDOM % ${#POSITIVE_EMOJI[@]} ]}

  read -r -d '' PAYLOAD << EndOfSuccess
  {
    "success": true,
    "service": "${GITHUB_REPOSITORY}",
    "dockerTag": "${DOCKER_TAG}",
    "dockerLatest": "${DOCKER_LATEST_TAG}",
    "text": ":white_check_mark: \nBuild <${BUILD_URL}|#${BUILD_NUMBER}> (<${COMPARE_URL}|${COMMIT_HASH}>) of *${GITHUB_REPOSITORY}@${GIT_BRANCH}* \nby ${AUTHOR} passed $EMOJI \n${GITHUB_COMMIT_MESSAGE_NL}"
  }
EndOfSuccess
else
  EMOJI=${NEGATIVE_EMOJI[$RANDOM % ${#NEGATIVE_EMOJI[@]} ]}

  read -r -d '' PAYLOAD << EndOfFailure
  {
    "success": false,
    "text": ":no_entry: \nBuild <${BUILD_URL}|#${BUILD_NUMBER}> (<${COMPARE_URL}|${COMMIT_HASH}>) of *${GITHUB_REPOSITORY}@${GIT_BRANCH}* \nby ${AUTHOR} failed $EMOJI \n${GITHUB_COMMIT_MESSAGE_NL}"
  }
EndOfFailure
fi

curl -X POST -H 'Content-Type: application/json' --data "${PAYLOAD}" $CI_BOT_WEBHOOK
