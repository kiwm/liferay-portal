#!/bin/bash

BLOCKERS=$(curl --request GET --url 'https://liferay.atlassian.net/rest/api/3/search?jql=labels%20%3D%20bpm-AUTOMATION%20and%20status%20%21%3D%20Closed&fields=issuekey' --user "jira-cloud-enterprisereleasehu@liferay.com:<$JIRA_TOKEN>" --header 'Accept: application/json' | jq -r '.issues[].key')

NOT_YET_MERGED_TICKETS=""

for BLOCKER in ${BLOCKERS[@]}
do
    GIT_LOG_GREP_RESULT=$(git log --grep="${BLOCKER}"" ")

    if [ -z "$GIT_LOG_GREP_RESULT" ]
    then
        NOT_YET_MERGED_TICKETS+=${BLOCKER}" "
    fi
done

if [ -z "$NOT_YET_MERGED_TICKETS" ]
then
    curl -X POST -H 'Content-type: application/json' --data '{"text":"All blockers are merged."}' "$SLACK_WEB_HOOK_URL"
else
    MESSAGE_NOT_YET_MERGED="These blockers still need to be merged: "$NOT_YET_MERGED_TICKETS

    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$MESSAGE_NOT_YET_MERGED\"}" "$SLACK_WEB_HOOK_URL"
fi