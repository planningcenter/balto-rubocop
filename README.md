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


## Contributing

### Local testing

1. Setup [act](https://github.com/nektos/act) (`brew install act`)
2. `npm test` (Note: this will download a large (6-12gb) docker image that
   matches what is ran on a GitHub action run)
