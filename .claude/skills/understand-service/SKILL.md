---
name: understand-service
description: Explains the hermes-agent-lightsail project to someone new — what it is for, its two containers, the Lightsail stack, how a release reaches the instance, stages, where skills go, and what it does NOT do yet. Use when onboarding or before a first change in hermes-agent-lightsail.
---

# Understand hermes-agent-lightsail

Walk the person through these points, pointing at the real files. Answer in the language they write in.

## 1. What it is (one paragraph)

A proof of concept to learn how to **deploy and maintain** an agent built with Hermes Agent (Nous
Research) on an AWS Lightsail VPS, all from a Docker dev container and with Infrastructure as Code.
There is no functionality yet: the agent answers questions through Telegram and `npm run chat`.

## 2. Where it sits in the repository

A standalone project: its own `.docker/`, `.envs/`, `serverless/`, docs and `.claude/`. It
deploys and depends on nothing else.

## 3. The two containers

- Dev container: `.devcontainer.json` + `.docker/` (`HermesAgent`): AWS CLI, Serverless, cfn-lint,
  SSH, envsubst, Claude Code.
- Agent container: `app/` (`Dockerfile` over the official image, `docker-compose.yml` with `gateway`
  and `dashboard`, `env.template`/`env.sh`, `skills/`).

## 4. Infrastructure and deploy

- `serverless/infrastructure`: Lightsail instance, static IP, SSH-only firewall, snapshot, SSM,
  `user-data.sh`, safeguards, deployment bucket.
- `scripts/lightsail.sh`: `deploy` (render `.env`, upload release, compose up), `rollback`, `status`,
  `logs`, `releases`, `chat`, `model`, `ssh`, `tunnel`, `token`, `ip` (`npm run ip-lightsail`), `key`, `myip`.
- Order: `npm run deploy-infra:<stage>` then `npm run deploy-app:<stage>`. Claude never deploys.

## 5. Stages and configuration

`dev`/`test`/`prod`; size in `custom.bundleIds`; `config.<stage>.env` / `aws.<stage>.env` are copied over `config.env` / `aws.env` to switch stage.
Details in `.claude/rules/environments.md`.

## 6. What to do when there is an objective

`.claude/rules/objective.md`: skills in `app/skills/`, model, keys, packages, channels, schedules.

## 7. What it does not do (yet)

Only `dev` is deployed; no HA (one node, daily snapshot); no automated tests; the fixed registration of
versioned skills (`skills.external_dirs`) has not run yet; Hermes Desktop through the tunnel is not
confirmed from the app. See "Open items" in `CLAUDE.md`.
