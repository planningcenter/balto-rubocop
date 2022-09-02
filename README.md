# 🐺 Balto

Balto is Smart and Fast:

* Installs _your_ version of ruby
* Installs _your_ versions of rubocop and rubocop extension gems
* _Only_ runs on files that have changed
* _Only_ annotates lines that have changed

Sample config (place in `.github/workflows/balto.yml`):

```yaml
name: Balto

on: [pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    permissions:
      checks: write # may not be necessary, see note below
    steps:
      - uses: actions/checkout@v1
      - name: Read ruby version
        run: echo ::set-output name=RUBY_VERSION::$(cat .ruby-version | cut -f 1,2 -d .)
        id: rv
      - uses: actions/setup-ruby@v1
        with:
          ruby-version: "${{ steps.rv.outputs.RUBY_VERSION }}"
      - uses: planningcenter/balto-rubocop@v0.6
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          conclusionLevel: "neutral"
```

## Inputs

| Name | Description | Required | Default |
|:-:|:-:|:-:|:-:|
| `conclusionLevel` | Which check run conclusion type to use when annotations are created (`"neutral"` or `"failure"` are most common). See [GitHub Checks documentation](https://developer.github.com/v3/checks/runs/#parameters) for all available options.  | no | `"neutral"` |

## Outputs

| Name | Description |
|:-:|:-:|
| `issuesCount` | Number of Rubocop violations found |

## A note about permissions

In the sample config above, we explicitly give `write` permissons to the [checks API](https://docs.github.com/en/rest/checks/runs) for the job that includes balto-rubocop as a step. Because balto-rubocop uses [check runs](https://docs.github.com/en/rest/guides/getting-started-with-the-checks-api), the `GITHUB_TOKEN` used in an action must have permissions to create a `check run`. 

Because some tools, like [dependabot](https://github.com/dependabot), have read-only permissions by default, you'll need to elevate its permissions for this to work with those sorts of tools. If you don't use any of those tools and your workflow will only run when users with permissions in the repo create and update pull requests, you may not need these explicit permissions at all.

## Contributing

### Local testing

1. Setup [act](https://github.com/nektos/act) (`brew install act`)
2. `npm test` (Note: this will download a large (6-12gb) docker image that
   matches what is ran on a GitHub action run)
