---
name: add-hermes-skill
description: Create or change a Hermes skill for the hermes-agent-lightsail agent in app/skills/ — from an objective, write SKILL.md (+ references/scripts), declare the env vars or packages it needs, check it and give the owner the deploy command. Use when the owner has a goal the agent should learn.
---

# Add or change a Hermes skill

Skills are the unit of "what the agent can do". They are Markdown instructions, not code.
Read `.claude/rules/skills.md` and `.claude/rules/objective.md` first.

## 1. Understand the objective

Ask (or infer) in one pass: what outcome, when it is triggered (user words), which inputs and
tools it needs (APIs, CLI packages), what it must never do. If it needs an API key or a
package, plan step 4.

## 2. Create the folder

```bash
mkdir -p app/skills/<kebab-name> && touch app/skills/<kebab-name>/SKILL.md   # then fill it from the template in app/skills/README.md
```

- `name:` equal to the folder; `description:` one sentence with what and when, using the
  words a user would type. It is the only thing the agent reads before deciding.
- Body: When to use / Steps (concrete, verifiable) / Notes (limits, never-do) / References.
- Long material → `references/*.md`; helpers → `scripts/` (bash/python the agent can run;
  the packages they need go in `EXTRA_APT_PACKAGES`).
- No secrets, no IPs, no personal data in the skill: it ships in every release.

## 3. Check

```bash
docker exec HermesAgent sh -c "cd /app && npm run format:check && npm run spell"
```

There are no automated tests: check by hand that `name` equals the folder and the frontmatter
has `name` and `description`. Add unknown words to `cspell.json`.

## 4. Declare what it needs

- API key: `.envs/config.env` + `app/env.template`, and the README glossary.
- Debian packages: `EXTRA_APT_PACKAGES` in `.envs/config.env`, `app/Dockerfile`
  and `app/docker-compose.yml`.
- A new channel: its variables and its allowlist (required).

## 5. Hand over

Add a line to `changelog.md`. Never deploy: give the owner `npm run deploy-app:dev`, then
`npm run chat` → `/skills` to confirm Hermes lists it (the deploy registers `/opt/skills` in
`skills.external_dirs`; see `.claude/rules/skills.md`). Then ask for the task in the skill's words.
