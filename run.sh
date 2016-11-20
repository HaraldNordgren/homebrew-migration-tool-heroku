#!/bin/bash

set -e

if [ -d homebrew-versions ]; then
    cd homebrew-versions
    git reset --hard -q
    git clean -fd
    git pull
else
    git clone https://github.com/HaraldNordgren/homebrew-versions
    cd homebrew-versions
    git remote add homebrew-versions-origin https://github.com/Homebrew/homebrew-versions
    git fetch homebrew-versions-origin
    git checkout -b homebrew-versions homebrew-versions-origin/master
fi

cd -
echo

if [ -d homebrew-migration-tool ]; then
    cd homebrew-migration-tool
    git pull
    cd -
else
    git clone https://github.com/HaraldNordgren/homebrew-migration-tool
fi

echo

homebrew-migration-tool/migrate.sh homebrew-versions
