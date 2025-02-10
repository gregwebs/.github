#!/usr/bin/env bash
set -euo pipefail

# Modified files
if ! git diff-index --exit-code HEAD -- >/dev/null ; then
	git update-index -q --really-refresh
	if ! git diff-index --exit-code HEAD -- >/dev/null ; then
		echo ""
		git diff >&2
		git diff-index HEAD -- >&2
		echo ""
		echo "  FATAL: there are dirty files $@" >&2
		echo ""
		exit 1
	fi
fi

if [[ $(git status --porcelain 2>/dev/null| grep "^??" | wc -l) != 0 ]] ; then
	git status --porcelain 2>/dev/null| grep "^??"
	echo ""
	echo "  FATAL: there are new files $@" >&2
	echo ""
	exit 1
fi