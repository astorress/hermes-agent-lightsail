# README

- [README](#readme)
  - [Summary](#summary)
  - [Setup](#setup)
    - [Development container](#development-container)
    - [Environment variables](#environment-variables)
    - [Dependencies](#dependencies)
    - [Deployment](#deployment)
    - [Remove](#remove)
  - [Contribution guidelines](#contribution-guidelines)
    - [Code review](#code-review)
    - [Other guidelines](#other-guidelines)
  - [Glossary](#glossary)
    - [Service environment variables: `.envs/config.env`](#service-environment-variables-envsconfigenv)
    - [Serverless Framework deployment variables](#serverless-framework-deployment-variables)

---

## Summary

`Hermes Agent` project deploys an agent built with [Hermes Agent](https://hermes-agent.nousresearch.com/) on an `Amazon Lightsail` instance. The agent uses a Claude model on `Amazon Bedrock` and is used through `Telegram` or `Hermes Desktop`.

These resources are created as `Infrastructure as Code` and deployed using `Serverless Framework`.

---

## Setup

### Development container

This steps are tailored to work with Visual Studio Code, but you are free to chose a different IDE and make necessary adjustments to the setup.

1. Install `ms-vscode-remote.remote-containers` extension. If you don't know how to do that follow this steps: <https://code.visualstudio.com/docs/editor/extension-gallery#_install-an-extension>
2. Open this project's folder in Visual Studio Code. The extension will detect a container configuration and will ask you if you want to reopen the project un the container. Accept.

### Environment variables

At `.envs` folder, you'll need to create env files with the variables described in the [Glossary](#glossary).

### Dependencies

This project does not depend on other `Cloud Formation Stacks`.

The Bedrock model (`BEDROCK_MODEL_ID`) must be available in the account. Anthropic models are enabled through an `AWS Marketplace` subscription on first use.

### Deployment

You can deploy `Cloud Formation Stacks` using `Serverless Framework` syntax: <https://www.serverless.com/framework/docs/providers/aws/cli-reference/deploy/>

Deployment order:

1. Deploy `serverless/infrastructure` stack
2. Deploy `app` release to the Lightsail instance with `scripts/lightsail.sh deploy`

### Remove

You must use `Serverless Framework` remove command as primary option: <https://www.serverless.com/framework/docs/providers/aws/cli-reference/remove/>

If `remove` command fails for whatever reason, you'll need to investigate the reason using `AWS Console` at your browser, solve the issue and then re-attempt the `remove` command.

You can, alternatively, delete the `AWS Cloud Formation` stack manually using `AWS Console` at your browser. But it's recommended to do it using the `remove` command from Serverless Framework.

---

## Contribution guidelines

### Code review

- Use known standards where situation allows it.
- Use known solutions for known problems.

### Other guidelines

- Investigate known and proven solutions before manufacturing your own.
- Check if our cloud provider offers a service you could use to solve the problem: evaluate ease of use, costs, maturity and reviews.
- If you need to use a library make sure it's mature, has continuos releases, it's stable.
- If a solution starts to get too messy, it's probably not the right solution.

---

## Glossary

### Service environment variables: `.envs/config.env`

- `SERVERLESS_ORG`: Name of your Serverless Framework org (set in `.envs/sls.env` next to `SERVERLESS_ACCESS_KEY`). It is part of the deployment bucket name
- `DEVELOPER`: Your username (letters, digits and dashes). It is used to guarantee unique resource names (deployment bucket) at deploy
- `ALLOWED_SSH_CIDR` _(Optional)_: Comma-separated CIDRs allowed to connect through SSH. If empty, port 22 is open to any IP (it still requires the key). E.g. `1.2.3.4/32`
- `SNAPSHOT_TIME_UTC` _(Optional)_: Time of the daily snapshot. Default value is `06:00`
- `HERMES_IMAGE_TAG` _(Optional)_: Tag of the `nousresearch/hermes-agent` image (`stable`, `latest` or a version). Default value is `stable`
- `BEDROCK_MODEL_ID` _(Optional)_: Bedrock inference profile with region prefix. Default value is `us.anthropic.claude-haiku-5-5`
- `EXTRA_APT_PACKAGES` _(Optional)_: Space-separated Debian packages installed in the agent image. Default value is `git jq curl unzip`
- `TELEGRAM_BOT_TOKEN` _(Optional)_: Token of the Telegram bot, from @BotFather
- `TELEGRAM_ALLOWED_USERS` _(Optional)_: Comma-separated numeric Telegram IDs allowed to talk to the agent. Required if `TELEGRAM_BOT_TOKEN` is set

### Serverless Framework deployment variables

- `stage`: Means the deployment stage. Values can be `dev`, `test` or `prod`
- Other deployment options can be set through CLI command. More info in the [Serverless Framework deploy CLI reference](https://www.serverless.com/framework/docs/providers/aws/cli-reference/deploy/)
