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
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v1
      - name: Read ruby version
        run: echo ::set-output name=RUBY_VERSION::$(cat .ruby-version | cut -f 1,2 -d .)
        id: rv
      - uses: actions/setup-ruby@v1
        with:
          ruby-version: "${{ steps.rv.outputs.RUBY_VERSION }}"
      - uses: planningcenter/balto-rubocop@v0.2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
