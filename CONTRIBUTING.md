# Contributing to persona-agents 🎭

> First off — thanks for wanting to make the horde bigger. Whether you're adding a new warband, a new profession, fixing a bug in the scripts, or just improving docs, contributions are welcome.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Branch & PR Workflow](#branch--pr-workflow)
- [Commit Messages](#commit-messages)
- [What You Can Contribute](#what-you-can-contribute)
  - [New Persona / Theme](#new-persona--theme)
  - [New Profession](#new-profession)
  - [Shell Script Changes](#shell-script-changes)
  - [JSON Changes](#json-changes)
- [CI Checks](#ci-checks)
- [File Structure Reference](#file-structure-reference)

---

## Code of Conduct

Be decent. This is a fun project — keep it that way. Harassment, discrimination, and general unpleasantness will get your PR closed and your issue locked.

---

## How to Contribute

1. **Fork** the repo and clone your fork locally.
2. **Create a branch** from `main` (see naming conventions below).
3. Make your changes.
4. **Test locally**
    - run `./generators/test/test_runner.sh` and check the test results. Update the tests if necessary.
    - run both generators to verify your changes:
      ```bash
      ./generators/generate_kiro.sh --output /tmp/test-kiro --theme your-theme
      ./generators/generate_opencode.sh --output /tmp/test-opencode --theme your-theme --agents-dir agents-generic --agents-json agents.json --skills-dir skills
      ```
    - or run `./install.sh --dry-run --target opencode --theme your-theme --profession orchestrator` to preview the full install flow for OpenCode.
5. Open a **Pull Request** against `main`.
6. CI must pass before merge. No exceptions.

---

## Branch & PR Workflow

This repo uses **trunk-based development**: `main` is always stable, and all work happens in short-lived feature branches that get merged and deleted.

**Branch naming:**

```
feat/add-starwars-theme
feat/add-medic-profession
fix/install-backup-overwrite
docs/update-contributing
chore/shellcheck-cleanup
```

Keep branches focused — one logical change per branch. Don't bundle a new persona with a script refactor in the same PR.

**Pull Requests:**

- Give the PR a clear title (mirrors the commit message format below).
- Briefly describe *what* changed and *why* in the PR description.
- If it's a new persona or theme, include a short character description so the reviewer (me) understands the personality before reading the markdown.

---

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add star wars theme with 7 personas
fix: install.sh not creating target directory before copy
docs: add profession table to README
chore: fix shellcheck warnings in update.sh
refactor: extract persona resolution logic in generate_kiro.sh
```

Keep the subject line under 72 characters. Add a body if the change needs context.

---

## What You Can Contribute

### New Persona / Theme

This is the most common contribution — a new fictional universe (theme) with a set of characters mapped to the existing professions.

**Steps:**

1. Create a directory: `personas/{your-theme}/`
2. Add one `.md` file per profession you're covering (orchestrator, planner, researcher, implementer, reviewer, tester, mascot). You don't need all seven, but the more the merrier.
3. Each persona file should define the character's **personality**, **speech style**, **quirks**, and how they approach their role. Look at `personas/goblin/bossnik-chief.md` for reference.
4. Add your theme's entries to `agents.json`:

```json
"your-theme": {
  "orchestrator": {
    "personaFile": "your-character.md",
    "description": "One sentence: who this is and what they bring.",
    "welcomeMessage": "Their first words when activated."
  }
}
```

5. Run **both** generators to test your theme:
    - `./generators/generate_kiro.sh --output /tmp/test-kiro --theme your-theme`
    - `./generators/generate_opencode.sh --output /tmp/test-opencode --theme your-theme --agents-dir agents-generic --agents-json agents.json --skills-dir skills`
    - Or run `./install.sh --target all --theme your-theme` to test both at once.

**Persona quality bar:**

- Each character should have a distinct voice — not just a name swap. The goblin reviewer (Grumbak) sounds *nothing* like the WH40K reviewer (Inquisitor Vane). Aim for that level of differentiation.
- The welcome message should be in-character. It's the first thing a user sees.
- Avoid generic fantasy tropes with no twist. "Wise old wizard" is boring. "Wise old wizard who is deeply passive-aggressive about being summoned for trivial tasks" is a character.

---

### New Profession

Adding a new profession (e.g., `devops`, `security`, `documenter`) requires changes in multiple places:

1. Add `professions/{profession}.md` — defines the role's responsibilities and behaviour.
2. Add `agents-generic/agent-{profession}.json` — defines tool permissions and agent capabilities for this role. Use an existing one as a template.
3. Add `skills/{profession}/` — at least one skill markdown file covering the profession's domain knowledge.
4. Add entries for the new profession to `agents.json` under each existing theme (or as many as make sense).
5. Update the install table in `README.md` to mention the new profession for both Kiro and OpenCode targets.

New professions need a stronger justification than new personas — open an Issue first to discuss whether the role makes sense within the existing architecture.

---

### Shell Script Changes

`install.sh`, `update.sh`, `generators/generate_kiro.sh`, `generators/generate_opencode.sh`, and `mappings/cli-mapping.json` are the core infrastructure. Changes here have the highest potential for breakage.

Rules:

- All shell scripts must pass `shellcheck` with no errors (this is enforced by CI).
- Test on both macOS and Linux if possible. The scripts are expected to work on both.
- Do not remove the backup logic from `update.sh`. Users' customised files must never be silently overwritten.
- If you add a new flag or behaviour to a script, update the relevant section in `README.md`.

---

### JSON Changes

`agents.json`, `agents-generic/*.json`, `mappings/cli-mapping.json`, and the schema files must all be valid JSON. CI validates this automatically with `jq`.

- Do not add comments to JSON files (they're not valid JSON).
- Keep `agents.json` entries consistent with the existing structure — `personaFile`, `description`, `welcomeMessage` are required fields per agent.
- If you change the agent schema, update `agents-generic/schema-agent.json` accordingly.
- If you change the CLI mapping, update `mappings/schema-mapping.json` accordingly.

---

## CI Checks

All PRs must pass the following checks before merge:

| Check | Tool | What it validates |
|---|---|---|
| Shell linting | `shellcheck` | No errors or warnings in `.sh` files |
| JSON validation | `jq` | All `.json` files are valid and parseable |

CI runs automatically on every push and PR. If checks fail, the PR cannot be merged. Fix the issues, push again, and the checks will re-run.

To run checks locally before pushing:

```bash
# Shell linting
shellcheck install.sh update.sh generators/generate_kiro.sh generators/generate_opencode.sh

# JSON validation (validates all JSON including mappings)
find . -name "*.json" | xargs -I{} jq empty {}
```

---

## File Structure Reference

```
persona-agents/
├── agents.json                  # Agent registry — add theme/profession entries here
├── agents-generic/              # Generic agent definitions (tool permissions, schemas)
│   ├── agent-{profession}.json  # One per profession
│   └── schema-agent.json        # Agent schema definition
├── personas/
│   └── {theme}/                 # One directory per theme
│       └── {character}.md       # One file per persona
├── professions/
│   └── {profession}.md          # Role behaviour definitions
├── skills/
│   └── {profession}/            # Skill docs organised by profession
├── mappings/
│   ├── cli-mapping.json         # Tool name mapping between Kiro and OpenCode
│   └── schema-mapping.json      # Mapping schema definition
├── generators/
│   ├── generate_kiro.sh         # Generates Kiro agent configs from generics + registry
│   ├── generate_opencode.sh     # Generates OpenCode agent configs from generics + registry
│   └── test/
│       ├── test_runner.sh       # Test runner for generators
│       ├── test-agents.json     # Test agent registry
│       ├── generics/            # Test generic agent definitions
│       ├── skills/              # Test skill definitions
│       └── reference/           # Expected test output for diff comparison
├── settings/
│   ├── kiro-cli.json.example    # Kiro CLI settings template
│   └── mcp.json.example         # MCP settings template
├── install.sh                   # Installs to ~/.kiro/ and/or ~/.config/opencode/
│                               # (supports --target, --theme, --profession, --dry-run, --force)
└── update.sh                    # git pull + reinstall with backup
```

---

## Questions?

Open an [Issue](https://github.com/las-pinter/persona-agents/issues) with the `question` label. Or just open a PR — if something's wrong, it'll get caught in review.

*WAAAGH!* (or whatever your theme's equivalent battle cry is)
