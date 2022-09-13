# CHANGELOG

## Unreleased

- **New**: install arbitrary gems through the `additionalGems` input (https://github.com/planningcenter/balto-rubocop/pull/19)
- **New**: support more project setups with new minimal Gemfile strategy (https://github.com/planningcenter/balto-rubocop/pull/19)
- **Breaking**: stop installing `standard` gem (when present) by default. Use `additionalGems` input instead (https://github.com/planningcenter/balto-rubocop/pull/19)

## v0.8 (2021-05-27)

- **New**: always report high severity offenses (https://github.com/planningcenter/balto-rubocop/pull/14)
- **New**: fail the check for high severity offenses (https://github.com/planningcenter/balto-rubocop/pull/14)

## v0.7 (2021-04-08)

- Make `push` events also work (https://github.com/planningcenter/balto-rubocop/pull/10)
- Add `issuesCount` output (https://github.com/planningcenter/balto-rubocop/pull/12)

## v0.6 (2020-10-02)

- Handle action run failures better (https://github.com/planningcenter/balto-rubocop/pull/9)
- Setup local testing (https://github.com/planningcenter/balto-rubocop/pull/8)
- Use bundle inline for more accurate dependency resolution (https://github.com/planningcenter/balto-rubocop/pull/6)

## v0.5 (2020-01-20)

- use `--force-exclusion` flag  to respect exclusions in `.rubocop.yml`

## v0.4 (2020-01-13)

- If a `Gemfile.lock` is not available, fallback to installing gems from a `[project-name].gemspec`.

https://github.com/planningcenter/balto-rubocop/pull/3

## v0.3 (2019-10-15)

- Conclusion level is configurable, and defaults to neutral

## v0.2 (2019-10-11)

- Small naming change

## v0.1 (2019-10-11)

- Add sample config to readme

