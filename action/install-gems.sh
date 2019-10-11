cat Gemfile.lock | \
    grep "\srubocop.* ([[:digit:]]" | \
    sed 's/\([a-z\-]\+\) (\(.*\))/\1:\2/' | \
    xargs | \
    xargs gem install -N
