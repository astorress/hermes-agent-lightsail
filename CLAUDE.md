# hermes-agent-lightsail — Hermes Agent on AWS Lightsail (generic deployment base)

## Repository context

`hermes-agent-lightsail` is a standalone project: it carries its own Docker setup, credentials
folder, docs and deploy tooling. It depends on nothing deployed by anyone else.

The goal today is **not a functionality**: it is to find out how to deploy and maintain
an agent built with [Hermes Agent](https://hermes-agent.nousresearch.com/) (Nous
Research) on a Lightsail VPS, all from a Docker dev container and with Infrastructure as
Code. The agent only answers questions, through Telegram and `npm run chat`. When a real
objective appears, `.claude/rules/objective.md` says where each change goes (skills, model, keys,
channels).

Status: **template, not deployed**. Deploying it to `dev` creates the stack `hermes-agents-infrastructure` and one release of
`app/`; the agent then answers through Telegram and `npm run chat` with Bedrock (Claude Haiku 5.5).
What is still open is under "Open items".

## Folder structure

```text
hermes-agent-lightsail/
├── .devcontainer.json, .docker/   # dev container (stage img-hermes): tools to develop and deploy
├── .envs/                         # aws.env, sls.env, config.env (git-ignored)
├── app/                           # what is deployed to the instance
│   ├── Dockerfile                 # official nousresearch/hermes-agent image + EXTRA_APT_PACKAGES
│   ├── docker-compose.yml         # gateway + dashboard, no published ports
│   ├── env.template, env.sh       # variables that travel to the server (envsubst → app/.env)
│   └── skills/                    # Hermes skills we version; mounted read-only at /opt/skills
├── serverless/infrastructure/     # Serverless Framework v4 → CloudFormation (Lightsail)
│   ├── serverless.yml, lightsail.yml, ssm.yml, cfn-collisions.yml
│   ├── iam.yml, secrets-manager.yml  # Bedrock IAM user (invoke one model only) + its key
│   ├── user-data.sh               # instance bootstrap (Docker, swap, /opt/hermes)
│   ├── allowed-cidrs.js           # ALLOWED_SSH_CIDR → firewall (empty = SSH open)
│   └── downloadSshKeyPair.sh      # default Lightsail key → ~/.ssh (deploy:finalize hook)
├── scripts/lightsail.sh           # deploy and day-2 operations over SSH
├── docs/                          # hermes.md (architecture, npm commands, Hermes Desktop; Spanish) + architecture.drawio
└── .claude/                       # rules, agent and skills for Claude Code
```

## Commands

Inside the dev container (`HermesAgent`, folder `/app`):

```bash
npm run format:check    # prettier (yml, md)
npm run spell           # cspell (en, es)
```

Deploy and operations are in `.claude/rules/deployment.md`.

## Conventions

- Stages are `dev`, `test`, `prod` (one AWS account per stage: names carry no stage).
  Per-stage differences: `custom.bundleIds` and the `config.env` / `aws.env` you copied for that stage. See
  `.claude/rules/environments.md`.
- **Claude never deploys** (`.claude/rules/deployment.md`).
- Secrets you write (the Telegram token) never enter CloudFormation or
  `user-data.sh`: they travel only in `app/.env` (0600), rendered at deploy time and deleted
  locally on exit. The one exception is generated, not written: the Bedrock IAM user's access key
  is created by the stack (`iam.yml`), stored in Secrets Manager (`secrets-manager.yml`) and
  read by `scripts/lightsail.sh deploy` as `BEDROCK_AWS_*`; never ship the deployer's `AWS_*`.
- Nothing publishes a port except SSH (22). It is open to any IP while `ALLOWED_SSH_CIDR` is empty (PoC decision,
  key-only); setting it restricts SSH to those CIDRs. Never publish another port.
- A channel with a bot token **requires** its allowlist (Hermes runs shell commands). Never
  use `*_ALLOW_ALL_USERS`.
- Do not override `ENTRYPOINT`/`CMD`/`USER` in `app/Dockerfile`: the base image's
  entrypoint starts s6-overlay.
- A new variable goes in `app/env.template` (if the agent needs it), in `.envs/config.env` and
  in the README glossary.
- Document every change in `changelog.md`. Markdown is formatted with prettier;
  user-facing docs are in Spanish, code and rules in English.
- Anything taken from the Hermes documentation and not run here is marked "not verified".

## `.claude/`

- `rules/`: `architecture.md`, `dependencies.md`, `deployment.md`, `environments.md`, `integrations.md`, `skills.md`.
- `agents/hermes-agent-expert`: expert on this project; `agents/deploy-validator`: checks readiness and returns the commands, never deploys.
- `skills/understand-service`: onboarding; `skills/validate-environment`: quick pre-deploy check; `skills/add-hermes-skill`: create or change a Hermes skill in `app/skills/`.

## Local development

Open the folder in VS Code and _Reopen in Container_ (`.devcontainer.json`): it builds
`.docker/Dockerfile` (stage `img-hermes`) as `HermesAgent`, mounts the project at `/app` and
`~/.ssh-hermes` at `/home/hermes/.ssh`, and `.docker/entrypoint.sh` configures git, runs
`npm install` and writes the AWS credentials. Outside VS Code:

```bash
docker compose -f .docker/docker-compose.yml up -d
docker exec -it HermesAgent bash
```

## Environment variables

`.envs/aws.env` and `.envs/sls.env` hold the credentials (`AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_REGION`, `AWS_DEFAULT_OUTPUT`, `SERVERLESS_ACCESS_KEY`);
`.envs/config.env` and `aws.env` are the only ones read: to change stage, copy
`config.<stage>.env` / `aws.<stage>.env` over them and rebuild the container (no overlay, so
variables of two stages never mix). All are git-ignored. The full list, with what each one does, is in
`.claude/rules/environments.md` and the README glossary.

## Deployment

`npm run deploy-infra:<stage>` creates the Lightsail stack and `npm run deploy-app:<stage>`
ships a release of `app/`; `npm run remove-infra:<stage>` removes the stack. Order, gotchas and
what Claude may and may not run: `.claude/rules/deployment.md`.

## Open items

- **Skills registration**: `lightsail.sh deploy` sets `skills.external_dirs` with `hermes config set`; after the first `deploy-app` with a skill in `app/skills/`, check `npm run chat` → `/skills`.
- Hermes Desktop: the dashboard session token (`npm run token`) is verified on the server; the connection from the desktop app is not confirmed.
- `test` and `prod`: never deployed.
- `docs/architecture.drawio` is the draw.io diagram (made with the `architecture-diagram` skill; `docs/hermes.md` holds the user-facing guide: architecture, `npm run` commands, Hermes Desktop). When the architecture changes, update the diagram, `docs/hermes.md` and `.claude/rules/architecture.md` together.

## Commit convention

One-line subject, imperative, no trailing period, followed by a body with one `- ` bullet per
distinct change. Empty folders that must exist are kept with a `.gitignore`, never `.gitkeep`.
One commit per distinct change. Claude only commits when the owner asks, and never pushes.

See `.claude/rules/` for detailed operational context.
