#!/bin/sh

set -ex

cd $GITHUB_WORKSPACE

GEMFILE_LOCK=$GITHUB_WORKSPACE/Gemfile.lock

if [ -r $GEMFILE_LOCK ]; then
    cat $GEMFILE_LOCK | \
        grep "\srubocop.* ([[:digit:]]" | \
        sed 's/\([a-z\-]\+\) (\(.*\))/\1:\2/' | \
        xargs | \
        xargs gem install
else
    echo "Can't find Gemfile.lock in Github worskpace!"
    exit 1
fi

ruby /action/action.rb
