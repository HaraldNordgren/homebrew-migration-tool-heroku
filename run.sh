#!/bin/bash

set -e

mkdir -p .ssh
echo "$GITHUB_PRIVATE_SSH_KEY" > .ssh/id_rsa
chmod 600 .ssh/id_rsa
#ssh -i .ssh/id_rsa -oStrictHostKeyChecking=no -T git@github.com
#ssh-add .ssh/id_rsa < /dev/null

if [ -d homebrew-versions ]; then
    cd homebrew-versions
    git reset --hard -q
    git clean -fd
    git pull
else
    #git clone https://github.com/HaraldNordgren/homebrew-versions
    git clone git@github.com:HaraldNordgren/homebrew-versions.git
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
