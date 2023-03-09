# 🐺 Balto

Balto is Smart and Fast:

* Installs _your_ versions of rubocop and rubocop extension gems
* _Only_ runs on files that have changed
* _Only_ annotates lines that have changed

Sample config (place in `.github/workflows/balto.yml`):

```yaml
name: Balto

on: [pull_request]

jobs:
  rubocop:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - uses: ruby/setup-ruby@v1
      - uses: planningcenter/balto-rubocop@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Name | Description | Required | Default |
|:-:|-|:-:|:-:|
| `rootDirectory` | The root directory to use for running the action | no | `"."` |
| `conclusionLevel` | Which workflow status should be used when annotations are created. Currently, `"failure"` and `"action_required"` show as failures, while everything else (including `"neutral"`) show as successful | no | `"neutral"` |
| `additionalGems` | Comma-separated list of other gems that your RuboCop setup depends on, in addition to gems starting with "rubocop", which are installed by default.  | no | `""` |
## Outputs

| Name | Description |
|:-:|:-:|
| `issuesCount` | Number of Rubocop violations found |

## Contributing

### Local testing

1. Setup [act](https://github.com/nektos/act) (`brew install act`)
2. `npm test` (Note: this will download a large (6-12gb) docker image that
   matches what is ran on a GitHub action run)
