#!/bin/bash

SLACK_WEB_HOOK_URL=""

JIRA_TOKEN=""

function main() {
    local blockers_keys=($(curl --request GET --url 'https://liferay.atlassian.net/rest/api/3/search?jql=project%20%3D%20%22PUBLIC%20-%20Liferay%20Product%20Delivery%22%20and%20labels%20%3D%20release-blocker%20and%20status%20%21%3D%20Closed&fields=issuekey' --user "jira-cloud-enterprisereleasehu@liferay.com:<$JIRA_TOKEN>" --header 'Accept: application/json' | jq -r '.issues[].key'))

    if [ ! -d "/home/me/liferay-portal" ]
    then
       git clone git@github.com:liferay/liferay-portal.git
    fi

    cd liferay-portal || exit 3

    local git_pull_response

    git_pull_response=$(git pull origin master)

    if [[ "${git_pull_response}" == *"Already up to date"* ]]
    then
        exit 4
    fi

    local not_yet_merged_blockers=""

    for blocker_key in "${blockers_keys[@]}"
    do
        local git_log_grep_result

        git_log_grep_result=$(git log --grep="${blocker_key}")

        if [ -z "${git_log_grep_result}" ]
        then
            not_yet_merged_blockers+="<https://liferay.atlassian.net/browse/${blocker_key}|${blocker_key}> "
        fi
    done

    local slack_message="All blockers are merged"

    if [ -n "${not_yet_merged_blockers}" ]
    then
        slack_message+="These blockers still need to be merged: ${not_yet_merged_blockers}"
    fi

    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${slack_message}\"}" "${SLACK_WEB_HOOK_URL}"
}

main
