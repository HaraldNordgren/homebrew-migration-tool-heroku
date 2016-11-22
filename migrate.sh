#!/bin/bash

set -e

function go_to_sleep {
    echo "Going to sleep for 5 minutes ..."
    echo
    sleep 300
}

#base_dir="$(dirname $BASH_SOURCE)"
base_dir=$PWD
migrate_versions="$base_dir"/homebrew-migration-tool/migrate_versions.rb

if [ -z "$1" ]; then
    echo "Supply repo dir to migrate"
    exit 1
fi

cd "$1"

git checkout homebrew-versions -q
git reset --hard -q
git clean -fd

leftover_branches="$(git branch | grep homebrew-versions-)" || true
if [ -n "$leftover_branches" ]; then
    echo
    while read -r branch; do
        git branch -D $branch
    done <<< "$leftover_branches"
fi

echo

while :; do
    echo "PULLING LATEST COMMITS FROM HOMEBREW-VERSIONS"
    git pull

    latest_homebrew_commit=$(git rev-parse HEAD)
    if git log master --pretty=%B | grep -q $latest_homebrew_commit ; then
        echo "NOTHING NEW TO MIGRATE"
        go_to_sleep
        continue
    fi

    staging_branch=homebrew-versions-$latest_homebrew_commit

    echo
    git checkout -b $staging_branch

    ruby "$migrate_versions"
    git add . -A
    git commit -m "Migrated 'Homebrew/homebrew-versions' up to $latest_homebrew_commit" -q

    echo "MERGING BRANCHES"
    git checkout master -q
    git merge $staging_branch -X theirs --no-edit -q

    echo
    echo "PUSHING TO REMOTE"
    git push
    git branch -d $staging_branch

    git checkout homebrew-versions -q

    echo "MIGRATION COMPLETED"
    go_to_sleep    
done

