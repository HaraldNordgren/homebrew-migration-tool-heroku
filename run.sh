#!/bin/bash

set -e
#set -x

base_dir="$PWD"
script_dir="$base_dir"/scripts
static_dir="$base_dir"/static-files

export migrate_versions="$script_dir"/migrate_versions.rb
export construct_travis_yml="$script_dir"/construct_travis_yml.rb
export new_travis_yml="new_travis_yml.yml"

versions_short="HaraldNordgren/homebrew-versions"
reference_short="HaraldNordgren/homebrew-versions-reference"

travis_string="Updated build suite ($(ruby -e 'print Time.now.getlocal("+01:00")'))"

# Running on Heroku
if [ -n "$GITHUB_PRIVATE_SSH_KEY" ]; then
    nc -k -l $PORT &

    mkdir -p .ssh
    echo "$GITHUB_PRIVATE_SSH_KEY" > .ssh/id_rsa
    chmod 600 .ssh/id_rsa
    ssh-keyscan github.com >> .ssh/known_hosts

    export github_address_versions="git@github.com:${versions_short}.git"
    export github_address_reference="git@github.com:${reference_short}.git"

# Running locally
else
    rm -rf homebrew-versions homebrew-reference
    export github_address_versions="https://github.com/${$versions_short}.git"
    export github_address_reference="https://github.com/${reference_short}.git"
fi

function configure_git {
    git config user.email "haraldnordgren+homebrew-version-migration-bot@gmail.com"
    git config user.name "homebrew-version-migration-bot"
    git config push.default simple
}

function copy_build_formula {
    build_formula="$static_dir"/build_formula.rb
    mkdir -p tests
    cp "$build_formula" tests
    git add tests/build_formula.rb
}

function copy_readme {
    readme="$static_dir"/migrated_versions_README.md
    cp "$readme" README.md
    git add README.md
}

function migrate_versions {(
    echo
    echo "CLONING $github_address_versions"
    git clone $github_address_versions homebrew-versions
    cd homebrew-versions

    git remote add homebrew-versions-origin https://github.com/Homebrew/homebrew-versions
    git fetch homebrew-versions-origin
    git checkout -b homebrew-versions homebrew-versions-origin/master -q

    configure_git

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
        git checkout master
        ruby "$construct_travis_yml" versions "$new_travis_yml"

        mv "$new_travis_yml" .travis.yml
        git add .travis.yml

        copy_build_formula
        copy_readme

        if [[ $(git status --porcelain) ]]; then
            git commit -m "$travis_string"
            git push
        else
            echo "NOTHING NEW TO MIGRATE"
        fi
        return
    fi

    for commit in $unmigrated_commits; do
        echo
        echo "MIGRATING $commit"
        staging_branch=homebrew-versions-$commit
        git checkout -b $staging_branch $commit

        git checkout master migrated_packages.json || true
        ruby "$migrate_versions"

        # Ruby processing to avoid spammy notifications on push
        homebrew_message=$(git log $commit --pretty=%B -n1 | ruby -ne 'print $_.sub(/^@/, "").gsub(/ @/, " ")')
        git commit -m "Migrating $commit: '$homebrew_message'" -q

        migration_hash=$(git rev-parse HEAD)

        echo
        echo "MERGING BRANCHES"
        git checkout master -q

        git checkout $migration_hash Formula Aliases
        git checkout $migration_hash LICENSE || true
        git checkout $migration_hash migrated_packages.json
        
        pwd
        ll *
        ruby "$construct_travis_yml" versions "$new_travis_yml"
        mv "$new_travis_yml" .travis.yml
        git add .travis.yml

        copy_build_formula
        copy_readme

        git status -u

        if [ -n "$(git status --porcelain)" ]; then
            git commit -m "Migrated $commit: '$homebrew_message'" -q
        else
            git commit -m "[skip ci] Migrated $commit: '$homebrew_message'" --allow-empty -q
        fi

        echo
        echo "PUSHING TO REMOTE"
        git push

        git branch -D $staging_branch

        echo "####################################################"
    done

    echo "MIGRATION COMPLETED"
)}

function migrate_reference {(
    echo
    echo "CLONING $github_address_reference"
    git clone $github_address_reference homebrew-versions-reference
    cd homebrew-versions-reference

    configure_git

    ruby "$construct_travis_yml" reference "$new_travis_yml"
    mv "$new_travis_yml" .travis.yml
    git add .travis.yml
    copy_build_formula

    if [[ $(git status --porcelain) ]]; then
        git commit -m "$travis_string"
        git push
    else
        echo "TRAVIS YML ALREADY UP-TO-DATE"
    fi
)}


migrate_versions
migrate_reference
