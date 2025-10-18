# Install Session Manager plugin for the AWS CLI

[![tests](https://github.com/ankurk91/install-session-manager-plugin-action/actions/workflows/tests.yaml/badge.svg)](https://github.com/ankurk91/install-session-manager-plugin-action/actions)
[![lint](https://github.com/ankurk91/install-session-manager-plugin-action/actions/workflows/lint.yaml/badge.svg)](https://github.com/ankurk91/install-session-manager-plugin-action/actions)

GitHub action to install Session Manager plugin for the AWS CLI

### Features

* Cache and restore the downloaded binary
* Tested on GitHub and Gitea Actions
* Tested on Ubuntu and Amazon Linux 3 runners (`X86_64` and `arm64`)

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
      - name: Install Session manager plugin
        uses: ankurk91/install-session-manager-plugin-action@v1
        with:
          cache: true # or set to false, true by default

      - name: Start session
        run: aws ssm start-session --target instance-id
```

### Input options

| Name    | Required | Default | Description                               |
|---------|----------|---------|-------------------------------------------|
| `cache` | No       | `true`  | Whether to cache the downloaded installer |

### Must read

> [!IMPORTANT]
> This action assumes that your runner has AWS CLI preinstalled.

> [!NOTE]
> This action uses bash scripts and requires `curl` to be preinstalled.

### Ref links

* https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html

### License

This repo is licensed under MIT [License](LICENSE.txt).