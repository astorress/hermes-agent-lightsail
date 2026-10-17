# When there is an objective — hermes-agent-lightsail

Today the agent only answers questions. This says **where each thing goes** once there is a
concrete objective (for example "summarize my emails every morning"). Items marked ⚠️ come from
Hermes' documentation and were not tested here.

## Map: what the owner wants → what changes

| Wants…                                          | Change                                                                         | Published with                                               |
| ----------------------------------------------- | ------------------------------------------------------------------------------ | ------------------------------------------------------------ |
| Teach it a procedure (skill)                    | `app/skills/<name>/SKILL.md` (+ `references/`, `scripts/`)                     | `npm run deploy-app:dev`                                     |
| A personality or fixed rules                    | `/opt/hermes/data/SOUL.md` on the server (`npm run ssh`) ⚠️                    | not in git                                                   |
| Choose the model                                | `BEDROCK_MODEL_ID` (+ `deploy-infra`), or `npm run model`                      | `npm run deploy-app:dev`                                     |
| System tools (git, jq, ffmpeg…)                 | `EXTRA_APT_PACKAGES` in `.envs/config.env`                                     | `npm run deploy-app:dev` (rebuilds the image)                |
| A service API key                               | new variable in `.envs/config.env` and `app/env.template`                      | `npm run deploy-app:dev`                                     |
| Another channel (Discord, Slack…)               | the channel's variables, as above (with its allowlist)                         | `npm run deploy-app:dev`                                     |
| Scheduled tasks                                 | asked in chat or with `hermes cron` inside the container ⚠️                    | `npm run chat`                                               |
| More server capacity                            | `custom.bundleIds` in `serverless/infrastructure/serverless.yml`               | `npm run deploy-infra:dev`                                   |
| A separate agent (other objective, other secrets) | another stage with its `config.<stage>.env` and `aws.<stage>.env`            | `npm run deploy-infra:<stage>` and `npm run deploy-app:<stage>` |

## Recommended flow

1. Write the objective in one sentence, plus what the agent must be able to do and what it must never do.
2. **Create the skill** (the most important part: the agent follows instructions, not code): `add-hermes-skill`, or `mkdir app/skills/<name>` and fill `SKILL.md` from the template in `app/skills/README.md`. `name` must equal the folder.
3. **Declare what it needs**: keys in `.envs/config.env` (+ `env.template`), packages in `EXTRA_APT_PACKAGES`. A new secret never goes in CloudFormation.
4. **Deploy** (the owner): `npm run deploy-app:dev`, then `npm run status` and `npm run logs`.
5. **Test** with `npm run chat` (or Telegram) asking for what the skill says. If it is not used, improve the `description`: it is the only thing read before deciding to load it.
6. **Record the change** in `changelog.md`.

## Repo skills vs. the agent's skills

- `app/skills/` → the ones the owner versions; shipped in every release, read-only in the container (`/opt/skills`).
- `/opt/hermes/data/skills` → the ones Hermes writes itself or installs from the hub (`/skills install …`). They live in the server volume, covered by the daily snapshot but not by git. If one is good, copy it to `app/skills/`.
- `.claude/skills/` → Claude Code skills for working in this repo (not Hermes').

## Before going beyond a PoC

- Pin `HERMES_IMAGE_TAG` to a version (not `stable`).
- Keep the channel allowlist; the agent has a terminal.
- Consider a separate `prod` stage and a manual snapshot before any `remove`.
