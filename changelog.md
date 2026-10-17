# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

- New: Hermes Agent on an Amazon Lightsail instance with static IP, SSH-only firewall, daily snapshot and SSM parameters (`serverless/infrastructure`), deployed with Serverless Framework
- New: stages `dev`, `test` and `prod` (the `allowed-stages` safeguard rejects others), each meant for its own AWS account; instance size per stage in `custom.bundleIds`
- New: Amazon Bedrock with Claude Haiku as the only model provider: an IAM user limited to invoking that model and its key in Secrets Manager (`iam.yml`, `secrets-manager.yml`), no third-party API key
- New: `app/` (Dockerfile + compose with `gateway` and `dashboard`) shipped as releases over SSH by `scripts/lightsail.sh` (`deploy`, `rollback`, `status`, `logs`, `chat`, `model`, `ssh`, `tunnel`, `ip`, `token`)
- New: empty `app/skills/` ready for your skills (mounted read-only at `/opt/skills` and registered in `skills.external_dirs`), with the `SKILL.md` template in `app/skills/README.md`
- New: Telegram as the default channel, with an allowlist of user IDs
- New: dev container, `CLAUDE.md` and `.claude/` (rules, `deploy-validator` and `hermes-agent-expert` agents, `validate-environment`, `understand-service` and `add-hermes-skill` skills), `cspell.json`, `ws.code-workspace`
- New: `docs/hermes.md` and the draw.io diagram `docs/architecture.drawio`
