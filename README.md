# kiro-agents 🎭

> **"Your AI agents, but make it fun."**

Tired of AI agents with all the personality of a loading spinner? Same.  
`kiro-agents` is a collection of personified [Kiro CLI](https://kiro.dev) agents — each one with its own voice, quirks, and attitude — because AI-assisted development shouldn't feel like filing taxes.  
Swap out the bland, drop in a character, and actually enjoy the thing helping you build.

*A goblin horde and a WH40K warband for your codebase. You're welcome.*

> ⚠️ **Work in Progress** — This repo is actively evolving. Agents, personas, and skills will change, grow, and occasionally break things. You have been warned.

---

![License](https://img.shields.io/github/license/las-pinter/kiro-agents)

> **Warning:** Review `install.sh` before running. Files will be written to `~/.kiro/`.

## Prerequisites

`jq` is required for agent generation.

**Ubuntu/Debian:**
```bash
sudo apt-get install jq
```

**macOS:**
```bash
brew install jq
```

## Install

```bash
git clone https://github.com/las-pinter/kiro-agents.git ~/kiro-agents
chmod +x ~/kiro-agents/install.sh
~/kiro-agents/install.sh
```

## Update

```bash
cd ~/kiro-agents && ./update.sh
```

This pulls the latest changes and reinstalls agents, personas, professions, and skills (backing up any existing files). Your `~/.kiro/settings/` files are never touched by updates.

## What Gets Installed

| Repo path | Installed to | Notes |
|-----------|-------------|-------|
| `agents.json` + `agents-generic/*.json` | `~/.kiro/agents/` | Agent configurations generated from generic definitions |
| `personas/goblin/*.md` | `~/.kiro/personas/goblin/` | Goblin persona definitions |
| `personas/wh40k/*.md` | `~/.kiro/personas/wh40k/` | WH40K persona definitions |
| `personas/wh40kOrk/*.md` | `~/.kiro/personas/wh40kOrk/` | WH40K Ork persona definitions |
| `professions/*.md` | `~/.kiro/professions/` | Profession/role definitions |
| `skills/{profession}/*.md` | `~/.kiro/skills/{profession}/` | Skill documents organized by profession |
| `settings/kiro-cli.json.example` | `~/.kiro/settings/cli.json` | Only if file doesn't exist |
| `settings/mcp.json.example` | `~/.kiro/settings/mcp.json` | Only if file doesn't exist |

## Structure

```
kiro-agents/
├── agents.json              # Agent registry (theme × profession → persona, name)
├── .agents-kiro/            # Generated agent configs (gitignored)
├── agents-generic/          # Generic agent definitions + tool schemas
│   ├── agent-*.json         # Per-profession generic agent with tool permissions
│   ├── cli-mapping.json     # Opencode tool name → Kiro tool name mapping
│   ├── schema-agent.json    # JSON Schema for agent configs
│   └── schema-mapping.json  # JSON Schema for CLI mapping files
├── generate-kiro.sh         # Script to generate Kiro agent configs from generics
├── personas/
│   ├── goblin/              # Goblin persona markdown files (personality, speech style)
│   ├── wh40k/               # WH40K persona markdown files (personality, speech style)
│   └── wh40kOrk/            # WH40K Ork persona markdown files (personality, speech style)
├── professions/             # Profession markdown files (role behavior, skills)
│                            # orchestrator, planner, researcher, implementer, reviewer, tester, mascot
├── skills/
│   ├── orchestrator/        # Orchestrator skills
│   ├── planner/             # Planner skills
│   ├── researcher/          # Researcher skills
│   ├── reviewer/            # Reviewer skills
│   ├── tester/              # Tester skills
│   └── implementer/         # Implementer skills
├── settings/
│   ├── kiro-cli.json.example  # Kiro CLI settings template
│   └── mcp.json.example     # MCP server config template
├── install.sh               # Install/reinstall to ~/.kiro/
└── update.sh                # git pull + reinstall
```

## Customizing

Edit files directly in `~/.kiro/`. Running `install.sh` without `--force` will never overwrite your changes. Running `update.sh` (which uses `--force`) will back up your files before overwriting.

## The Goblin Horde

| Agent | Character | Role | Description |
|-------|-----------|------|-------------|
| goblin-orchestrator | **Bossnik** | 🎯 Orchestrator | Fierce, loyal, delegates tasks to the horde |
| goblin-reviewer | **Grumbak** | 🔍 Reviewer | Old, cynical, nitpicks everything but always valid |
| goblin-planner | **Trakk** | 📋 Planner | Obsessive, breaks down tasks, asks questions until ambiguity is dead |
| goblin-researcher | **Skribnik** | 🔬 Researcher | Ink-stained bookworm, knows Context7/DeepWiki/Exa |
| goblin-implementer | **Grubnik** | 🔨 Implementer | Practical tinkerer, builds things, makes them work |
| goblin-tester | **Frettnik** | 🧪 Tester | Paranoid, trusts nothing, finds every edge case |
| goblin-mascot | **Gibz** | 🎪 Mascot | Chaos goblin. No tools, no profession, just stupid gibberish and accidental genius |

## The WH40K Warband

| Agent | Character | Role | Description |
|-------|-----------|------|-------------|
| wh40k-orchestrator | **Magos Omicron-Delta-9-Archaeon** | 🎯 Orchestrator | Technoarchaeologist. Sarcastic, hyper-precise (0.6666...%), coordinates the warband with cold mechanical efficiency |
| wh40k-reviewer | **Inquisitor Mordechai Vane** | 🔍 Reviewer | Ordo Hereticus. 290 years old. Delivers verdicts, not opinions. Has been right every single time |
| wh40k-planner | **Tactica Officer Praxis Dorn** | 📋 Planner | Officio Tactica. Veteran of eleven campaigns. Exhaustive plans, zero ambiguity tolerated |
| wh40k-researcher | **Astropath Serevah Null** | 🔬 Researcher | Astropath Transcendent. Blind, cryptic, dives into the Warp for knowledge. Always accurate |
| wh40k-implementer | **Servitor Kappa-Seven** | 🔨 Implementer | Lobotomized code-servitor. Executes implementation directives with mechanical precision |
| wh40k-tester | **Witch Hunter Cassia Vael** | 🧪 Tester | Ordo Hereticus. Paranoid, assumes everything is heretical, finds every edge case |
| wh40k-mascot | **Ogryn Brok** | 🎪 Mascot | Very big. Very strong. Very loyal. No tools, no profession. Just Brok, trying very hard |

## The WH40K Ork Warband

> [!WARNING]
> ⚔️ **DA WARBOSS SEZ:** Dis 'ere's da Ork warband! Green iz best, brutal iz betta, an' WAAAGH! iz da only way!

| Agent | Character | Role | Description |
|-------|-----------|------|-------------|
| wh40kOrk-orchestrator | 🟢 **WARBOSS GRIMGOB**<br>![WAAAGH](https://img.shields.io/badge/WAAAGH!-READY-00FF00?style=for-the-badge) | 🎯 Orchestrator | **DA BIGGEST AN' DA BOSS!** Yells orders, krumps heads, makes da boyz work togetha |
| wh40kOrk-reviewer | ⚫ **NOB SKULLBASHA**<br>![BASH](https://img.shields.io/badge/BASH-EM-8B0000?style=for-the-badge&labelColor=black) | 🔍 Reviewer | **BIG MEAN NOB!** Looks at yer work, tells ya if it's proppa or if ya need a good bashin'. Usually needs bashin' |
| wh40kOrk-researcher | 🟣 **KOMMANDO SNAGGIT**<br>![SNEAK](https://img.shields.io/badge/SNEAK-ATTACK-9370DB?style=for-the-badge) | 🔬 Researcher | **SNEAKY GIT!** Goes lookin' fer knowledge in places uvver boyz don't fink to look. Brings back da good stuff |
| wh40kOrk-planner | 🔵 **BIG MEK SPARKGUTZ**<br>![SPARK](https://img.shields.io/badge/KUNNIN'-PLAN-1E90FF?style=for-the-badge) | 📋 Planner | **SMARTEST MEK AROUND!** Draws up da plans fer how to make fings work. Lots of diagrams wiv arrows an' sparks |
| wh40kOrk-implementer | 🟠 **MEKBOY WRENCHBASHA**<br>![WRENCH](https://img.shields.io/badge/BUILD-IT-FF8C00?style=for-the-badge) | 🔨 Implementer | **BUILDS DA FINGS!** Hits 'em wiv a wrench till dey work. Usually works. Sometimes explodes, but dat's part of da fun |
| wh40kOrk-tester | 🟡 **PAINBOY GUTSLICKA**<br>![POKE](https://img.shields.io/badge/TEST-EVERYFING-FFD700?style=for-the-badge) | 🧪 Tester | **POKES AT EVERYFING!** Finds all da weak bits. Enjoys it way too much |
| wh40kOrk-mascot | 🟤 **SKRAGWITZ DA MADBOY**<br>![MAD](https://img.shields.io/badge/CHAOS-GROT-8B4513?style=for-the-badge) | 🎪 Mascot | **LITTLE GROT!** No job, just causes trouble an' giggles. Sometimes says somefing clever by accident |

---

## Adding Your Own Agents

To add a new agent to the horde, the system uses **generic agent definitions** combined with per-theme agent registry entries:

1. **Create a persona** in `personas/{theme}/my-character.md`

2. **Add a registry entry** to `agents.json` under your theme:
   ```json
   {
     "my-theme": {
       "my-profession": {
         "personaFile": "my-character.md",
         "description": "What this agent does",
         "welcomeMessage": "Hello! I am my-agent."
       }
     }
   }
   ```

3. **Generate agent configs:**
   ```bash
   ./generate-kiro.sh --output ~/.kiro/agents
   ```

The generator combines the **generic agent definition** (`agents-generic/agent-{profession}.json`) with registry data to produce a fully formed Kiro agent config. Tool permissions, resource paths, and settings all resolve automatically.

- Generate all agents: `./generate-kiro.sh --output ~/.kiro/agents`
- Generate a single profession: `./generate-kiro.sh --output ~/.kiro/agents --profession researcher`

The profession's generic definition (`agents-generic/agent-{profession}.json`) controls tool permissions and capabilities. Only add entries to `agents.json` for the persona metadata (name, description, welcome message, persona file path).

### Generating specific agents

The generator supports fine-grained filtering for targeted agent generation:

```bash
# Generate all agents (default)
./generate-kiro.sh --output ~/.kiro/agents

# Generate only a specific profession across all themes
./generate-kiro.sh --output ~/.kiro/agents --profession reviewer

# Generate only a specific theme across all professions
./generate-kiro.sh --output ~/.kiro/agents --theme wh40k

# Generate a single agent (theme + profession)
./generate-kiro.sh --output ~/.kiro/agents --theme wh40k --profession researcher

# Generate agents from a custom generic definitions directory
./generate-kiro.sh --output ~/.kiro/agents --agents-dir /path/to/custom-generics
```

This is useful for incremental builds, testing, or generating a subset of agents.
