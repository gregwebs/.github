#!/usr/bin/env bash
set -euo pipefail

if [[ -z ${GITHUB_REPOSITORY:-} ]] ; then
  echo "GITHUB_REPOSITORY unset" >&2
  exit 1
fi

REPO_URL="https://github.com/${GITHUB_REPOSITORY}"
MSG="<$REPO_URL|$GITHUB_REPOSITORY>"

SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-''}
if [[ -z $SLACK_WEBHOOK_URL ]] ; then
    echo "SLACK_WEBHOOK_URL unset" >&2
    exit 1
fi

# debug
# set -x

FAILURE=${FAILURE:-''}
if [[ -z $FAILURE ]] || [[ $FAILURE == false ]] || [[ $FAILURE == 0 ]] ; then
    SLACK_EMOJI=${SLACK_EMOJI_SUCCESS-':borat-great-success:'}
else
    SLACK_EMOJI=${SLACK_EMOJI_FAILURE-':x:'}
fi

GITHUB_REF=${GITHUB_REF:-''}
if [[ -z $GITHUB_REF ]] ; then
    echo "GITHUB_REF unset. Release tags are not supported and will use the latest commit" >&2
fi

if echo "$GITHUB_REF" | grep 'refs/tags/' ; then
    TAG="$(echo "$GITHUB_REF" | cut -d '/' -f '3-100')"
    # CI_COMMIT_SHA="$(git rev-parse --short "$TAG")"
    url="$REPO_URL/releases/tag/${TAG}"
    MSG="$MSG <${url}|tag ${TAG}>"
else
    if echo "$GITHUB_REF" | grep 'refs/pull/' ; then
        pr_number="$(echo "$GITHUB_REF" | cut -d '/' -f '3-100')"
        url="$REPO_URL/pull/${pr_number}"
        MSG="$MSG <$url|pull request #${pr_number}>"
    else
        if echo "$GITHUB_REF" | grep 'refs/heads' ; then
            branch="$(echo "$GITHUB_REF" | cut -d '/' -f '3-100')"
            url="$REPO_URL/compare/${branch}"
            MSG="$MSG <$url|branch ${branch}>"
        fi
    fi
fi

# CI_COMMIT_SHA=${CI_COMMIT_SHA:-$(git rev-parse --short HEAD)}
# msg="$(git log --oneline "${CI_COMMIT_SHA}" -1)"
# url="$REPO_URL/commit/${CI_COMMIT_SHA}"
# MSG="$MSG <${url}|${msg}>"

MSG="$SLACK_EMOJI $* $MSG"

GITHUB_ACTOR=${GITHUB_ACTOR:-''}
if [[ -n $GITHUB_ACTOR ]] ; then
    MSG="$MSG by $GITHUB_ACTOR"
fi
GITHUB_TRIGGERING_ACTOR=${GITHUB_TRIGGERING_ACTOR:-''}
if [[ -n $GITHUB_TRIGGERING_ACTOR ]] ; then
    if ! [[ $GITHUB_TRIGGERING_ACTOR == "$GITHUB_ACTOR" ]] ; then
        MSG="$MSG ran by $GITHUB_TRIGGERING_ACTOR"
    fi
fi
GITHUB_WORKFLOW=${GITHUB_WORKFLOW:-''}
if [[ -n $GITHUB_WORKFLOW ]] ; then
    msg="from $GITHUB_WORKFLOW"
    if [[ -n ${GITHUB_JOB:-''} ]] ; then
        msg="$msg/$GITHUB_JOB"
    fi
    if [[ -n ${GITHUB_RUN_ID:-} ]] ; then
      MSG="$MSG <$REPO_URL/actions/runs/${GITHUB_RUN_ID}|$msg>"
    else
      MSG="$MSG $msg"
    fi
fi

data="{\"text\":\"$MSG\"}"

set +x # turn off debug if it is on

curl -X POST -H "Content-type: application/json" --data "$data" "$SLACK_WEBHOOK_URL"