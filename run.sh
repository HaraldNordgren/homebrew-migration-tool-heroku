#!/bin/bash

set -e

base_dir="$PWD"
migrate_versions="$base_dir"/migrate_versions.rb
#README="$base_dir"/homebrew-versions-harald-README/README.md

if [ -n "$GITHUB_PRIVATE_SSH_KEY" ]; then
    nc -k -l $PORT &

    mkdir -p .ssh
    echo "$GITHUB_PRIVATE_SSH_KEY" > .ssh/id_rsa
    chmod 600 .ssh/id_rsa
    ssh-keyscan github.com >> .ssh/known_hosts
    #github_adress="git@github.com:HaraldNordgren/homebrew-versions.git"
    github_adress="git@github.com:HaraldNordgren/homebrew-versions-cherry.git"
else
    rm -rf homebrew-versions
    #github_adress="https://github.com/HaraldNordgren/homebrew-versions.git"
    github_adress="https://github.com/HaraldNordgren/homebrew-versions-cherry.git"
fi

echo
git clone $github_adress homebrew-versions
cd homebrew-versions

git remote add homebrew-versions-origin https://github.com/Homebrew/homebrew-versions
git fetch homebrew-versions-origin
git checkout -b homebrew-versions homebrew-versions-origin/master -q

git config user.email "haraldnordgren+homebrew-version-migration-bot@gmail.com"
git config user.name "homebrew-version-migration-bot"
git config push.default simple

echo
echo "PULLING LATEST COMMITS FROM HOMEBREW-VERSIONS"
git pull

unmigrated_commits=

for hash in $(git log homebrew-versions --pretty=%H); do
    if git log master --pretty=%B | grep -q $hash; then
        break
    fi

    unmigrated_commits="$hash $unmigrated_commits"
done

if [ -z "$unmigrated_commits" ]; then
    echo "NOTHING NEW TO MIGRATE"
    exit 0
fi

for commit in $unmigrated_commits; do
    echo
    echo "MIGRATING $commit"
    staging_branch=homebrew-versions-$commit
    git checkout -b $staging_branch $commit

    ruby "$migrate_versions"

    git add .
    
    if [ -e README.md ]; then
        git reset README.md
    fi
    
    if [ -e LICENSE ]; then
        git reset LICENSE
    fi

    homebrew_message=$(git log $commit --pretty=%B -n1)
    git commit -m "Migrated $commit: '$homebrew_message'" -q

    migration_hash=$(git rev-parse HEAD)

    echo
    echo "MERGING BRANCHES"
    git checkout master -q

    if ! git cherry-pick $migration_hash -X theirs --no-edit --keep-redundant-commits; then
        echo
        echo "SOLVING CONFLICTS BY ADDING ALL FILES"
        git add .
        git -c core.editor=true cherry-pick --continue
    fi

    git branch -D $staging_branch

    echo
    echo "PUSHING TO REMOTE"
    git push
done

echo "MIGRATION COMPLETED"
exit 0

