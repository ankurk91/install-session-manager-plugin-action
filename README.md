# Install the Session Manager plugin for the AWS CLI

[![tests](https://github.com/ankurk91/install-session-manager-plugin-action/actions/workflows/tests.yaml/badge.svg)](https://github.com/ankurk91/install-session-manager-plugin-action/actions)
[![lint](https://github.com/ankurk91/install-session-manager-plugin-action/actions/workflows/lint.yaml/badge.svg)](https://github.com/ankurk91/install-session-manager-plugin-action/actions)

GitHub Action to install the Session Manager plugin for the AWS CLI.

### Features

* Caches and restores the downloaded installer, keyed on the resolved version
* Installs the latest release, or a version that you pin
* Installs with `apt-get`, `dnf` or `yum`, whichever the runner provides
* Tested on GitHub Actions and Gitea Actions
* Tested on Ubuntu and Amazon Linux 2023 runners (`x86_64` and `arm64`)

### Usage

```yaml
on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Install the Session Manager plugin
        uses: ankurk91/install-session-manager-plugin-action@v1
        with:
          cache: true # optional, defaults to true
          version: latest # optional, defaults to latest

      - name: Start session
        run: aws ssm start-session --target instance-id
```

### Input options

| Name      | Required | Default  | Description                                                  |
|-----------|----------|----------|--------------------------------------------------------------|
| `cache`   | No       | `true`   | Whether to cache the downloaded installer                    |
| `version` | No       | `latest` | The version to install, for example `1.2.835.0`, or `latest` |

With the default of `latest`, the action resolves the current version on every
run and includes it in the cache key, so that a new upstream release is picked
up rather than being masked by an older cache entry. Pin `version` instead to
keep a deployment pipeline on a known plugin build.

### Requirements

> [!IMPORTANT]
> This action assumes that the AWS CLI is already installed on your runner.

> [!NOTE]
> This action runs Bash scripts and requires `curl` to be installed on the runner.

### References

* https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html

### License

This repository is licensed under the MIT [License](LICENSE.txt).
