#!/bin/bash
set -euo pipefail

# ============================================================================
# generate-kiro.sh — Generate agent configs for Kiro
#
# Usage:
#   ./generate-kiro.sh --output DIR [--profession PROFESSION] [--theme THEME]
#                      [--agents-dir DIR] [--agents-json FILE]
#
# Options:
#   --output          Output directory for generated agent files (required)
#   --profession      Profession to generate (optional, filters by profession across themes)
#   --theme           Theme to generate (optional, filters by theme across professions)
#   --agents-dir      Directory containing generic agent definitions (.json files)
#                     (defaults to <repo>/agents-generic)
#   --agents-json     Path to agents registry JSON file (defaults to <repo>/agents.json)
#                     Useful when combined with --agents-dir for isolated test generation
#
# The tool mapping file (cli-mapping.json) is always loaded from <repo>/mappings/
# regardless of --agents-dir or --agents-json.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERIC_AGENTS_DIR="${SCRIPT_DIR}/../agents-generic"
MAPPING_FILE="${SCRIPT_DIR}/../mappings/cli-mapping.json"
AGENTS_JSON="${SCRIPT_DIR}/../agents.json"
OUTPUT_DIR=""
PROFESSION=""
THEME=""
AGENTS_DIR_OVERRIDE=""
AGENTS_JSON_OVERRIDE=""

usage() {
    echo "Usage: $0 --output DIR [--profession PROFESSION] [--theme THEME] [--agents-dir DIR] [--agents-json FILE]"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --output)
        if [[ -n "$2" && "$2" != --* ]]; then
            OUTPUT_DIR="$2"
            shift 2
        else
            echo "Error: --output requires a value."
            usage
        fi
        ;;
    --profession)
        if [[ -n "$2" && "$2" != --* ]]; then
            PROFESSION="$2"
            shift 2
        else
            echo "Error: --profession requires a value."
            usage
        fi
        ;;
    --theme)
        if [[ -n "$2" && "$2" != --* ]]; then
            THEME="$2"
            shift 2
        else
            echo "Error: --theme requires a value."
            usage
        fi
        ;;
    --agents-dir)
        if [[ -n "$2" && "$2" != --* ]]; then
            AGENTS_DIR_OVERRIDE="$2"
            shift 2
        else
            echo "Error: --agents-dir requires a value."
            usage
        fi
        ;;
    --agents-json)
        if [[ -n "$2" && "$2" != --* ]]; then
            AGENTS_JSON_OVERRIDE="$2"
            shift 2
        else
            echo "Error: --agents-json requires a value."
            usage
        fi
        ;;
    --help | -h)
        usage
        ;;
    *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
done

# Apply overrides if provided
if [ -n "${AGENTS_DIR_OVERRIDE}" ]; then
    GENERIC_AGENTS_DIR="${AGENTS_DIR_OVERRIDE}"
fi
if [ -n "${AGENTS_JSON_OVERRIDE}" ]; then
    AGENTS_JSON="${AGENTS_JSON_OVERRIDE}"
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq not found" >&2
    exit 1
fi

# Validate required args
if [ -z "${OUTPUT_DIR}" ]; then
    echo "Error: --output DIR is required."
    usage
fi

echo "Generating agents to ${OUTPUT_DIR}"
if [ -n "${PROFESSION}" ]; then
    echo "Generating only ${PROFESSION} agents"
fi
if [ -n "${THEME}" ]; then
    echo "Generating only ${THEME} theme agents"
fi

mkdir -p "${OUTPUT_DIR}"

THEMES=$(jq -r 'keys[]' "$AGENTS_JSON")

for theme in $THEMES; do
    if [ -n "${THEME}" ]; then
        if [ "$theme" != "${THEME}" ]; then
            continue
        fi
    fi
    for profession in $(jq -r ".[\"$theme\"] | keys[]" "$AGENTS_JSON"); do
        # Use --arg to safely inject theme name into jq (handles hyphens, special chars)
        _theme="$theme" && _profession="$profession"
        if [ -n "${PROFESSION}" ]; then
            if [ "$profession" != "$PROFESSION" ]; then
                continue
            fi
        fi

        generic_agent_file="$GENERIC_AGENTS_DIR/agent-$profession.json"

        if [ ! -f "$generic_agent_file" ]; then
            echo "Warning: Generic agent $generic_agent_file not found, skipping $agent_name" >&2
            continue
        fi

        generic_agent_file_subs=$(
            jq -R -s \
                --arg theme "${theme}" \
                'gsub("{{THEME}}"; $theme) |
                fromjson' \
                "${generic_agent_file}"
        )

        agent_name="${_theme}-${_profession}"
        persona_file=$(jq -r --arg t "$_theme" --arg p "$_profession" '.[$t][$p].personaFile' "${AGENTS_JSON}")
        description=$(jq -r --arg t "$_theme" --arg p "$_profession" '.[$t][$p].description' "${AGENTS_JSON}")
        welcome_message=$(jq -r --arg t "$_theme" --arg p "$_profession" '.[$t][$p].welcomeMessage' "${AGENTS_JSON}")

        resource_files='"file://~/.kiro/personas/'"$_theme"'/'"${persona_file}"'"'
        resource_files="${resource_files}"',"skill://~/.kiro/skills/'"$_profession"'/*/SKILL.md"'
        resources=$(jq -n --argjson arr '['"${resource_files}"']' '$arr')

        prompt="file://~/.kiro/professions/${profession}.md"

        tools_json=$(jq -n --argjson agent "${generic_agent_file_subs}" --slurpfile mapping "${MAPPING_FILE}" '
            ($agent.tools) as $tools |
            ($mapping[0].tools) as $toolsMap |

            # --- helpers for name translation & mapping key lookup ---
            def getKiroName($k):
                if ($toolsMap | has($k)) and ($toolsMap[$k] | has("kiro"))
                then $toolsMap[$k].kiro |
                     if type == "object" then .name // $k
                     elif type == "string" then .
                     else $k end
                else $k end;

            def getMappingKey($k; $field):
                if ($toolsMap | has($k)) and ($toolsMap[$k] | has("kiro"))
                then ($toolsMap[$k].kiro[$field] // null)
                else null end;

            def hasConfig($v):
                if ($v | type) == "object" then true
                else false end;

            def hasConfigAllowed($v):
                if hasConfig($v) then
                    $v |
                    to_entries[] |
                    select((.value) == "allow") as $allowed |
                    if $allowed | length > 0 then true else false end
                else false end;

            def hasConfigDefaultAllowed($v):
                if hasConfig($v) and ($v | has("default")) and ($v.default == "allowed") then true
                else false end;

            def translateName($k):
                getKiroName($k) as $kn |
                if ($toolsMap | has($k)) and ($toolsMap[$k] | has("kiro")) and ($toolsMap[$k].kiro == false) then empty
                else $kn end;

            def isToolConfigForKiro($t; $c):
                if ($toolsMap | has($t)) and ($toolsMap[$t] | has("kiro") and ($toolsMap[$t].kiro | has($c)))
                then true
                else false end;

            # --- toolsList ---
            (if ($tools.default == "allow" or $tools.default == "ask") then
                ["*"]
            else
                [ $tools | to_entries[] |
                    select(.key != "default") |
                    select(.value != "deny" or hasConfig(.value)) |
                    translateName(.key)
                ] | unique
            end) as $toolsList |

            # --- allowedTools: simple "allow" + config tools, keep config order ---
            ([ $tools | to_entries[] |
                    select(.key != "default") |
                    select(.value == "allow" or hasConfigDefaultAllowed(.value) or (.key == "subagent" and hasConfigAllowed(.value))) |
                    translateName(.key)
                ]) as $allowedTools |

            # --- toolsSettings: build, merge (write+edit), follows generic config key order, read mapping keys ---
            ([ $tools | to_entries[] |
                    select(.key != "default") |
                    select((.value | type) == "object") |
                    {
                        kn: getKiroName(.key),
                        ak: getMappingKey(.key; "allowedKey"),
                        dk: getMappingKey(.key; "deniedKey"),
                        kq: getMappingKey(.key; "askKey"),
                        cfg: .value
                    } |
                    select(.kn != null)
                ] |
                sort_by(.kn) |
                group_by(.kn) |
                map(
                    . as $g |
                    $g[0].kn as $kn |
                    $g[0].ak as $ak |
                    $g[0].dk as $dk |
                    $g[0].kq as $kq |
                    (any($g[]; .cfg.default == "ask")) as $hasAsk |
                    (any($g[]; .cfg.default == "deny")) as $hasDeny |
                    ([ $g[] | .cfg | to_entries[] |
                        select(.key != "default" and .value == "allow") | .key
                    ] | unique) as $allowed |
                    ([ $g[] | .cfg | to_entries[] |
                        select(.key != "default" and .value == "deny") | .key
                    ] | unique) as $denied |
                    ([ $g[] | .cfg | to_entries[] |
                        select(.key == "config") | .value |
                        select(type == "object") |
                        to_entries[] |
                        select(isToolConfigForKiro($kn; .key)) |
                        {(.key):(.value)}
                    ] | add) as $config |
                    (
                        (if $kq != null and $hasAsk then {($kq): ["*"]} else {} end) as $p |
                        (if $kq != null and $hasDeny then $p + {($kq): $allowed} else $p end) as $p2 |
                        (if $ak != null and ($allowed | length) > 0 then $p2 + {($ak): $allowed} else $p2 end) as $p3 |
                        (if $dk != null and ($denied | length) > 0 then $p3 + {($dk): $denied} else $p3 end) as $p4 |
                        ($p4 + $config) as $settings |
                        if ($settings | length) > 0 then {($kn): $settings} else {} end
                    )
                ) |
                reduce .[] as $g ({}; . + $g)
            ) as $toolsSettings |

            {
                tools: $toolsList,
                allowedTools: $allowedTools,
                toolsSettings: $toolsSettings
            }
        ')

        tools=$(echo "$tools_json" | jq '.tools')
        allowed_tools=$(echo "$tools_json" | jq '.allowedTools')
        tools_settings=$(echo "$tools_json" | jq '.toolsSettings')

        root_config_json=$(jq -n --slurpfile agent "${generic_agent_file}" --slurpfile mapping "${MAPPING_FILE}" '
            ($agent[0].config) as $config |
            ($mapping[0].config) as $configMap |

            def isConfigForKiro($k):
                if ($configMap | has($k)) and ($configMap[$k] | has("kiro"))
                then ($configMap[$k].kiro // null)
                else false end;

            # --- configurations: To check configurations which could go into the toolsSettings ---
            (if $config != null then
                [$config |
                to_entries[] |
                select(isConfigForKiro(.key)) |
                {(.key):(.value)}] | add
            else [] end
            ) as $rootConfig |

            {
                rootConfig: $rootConfig
            }
        ')

        root_config=$(echo "$root_config_json" | jq '.rootConfig')

        output_file="$OUTPUT_DIR/$agent_name.json"
        output=$(jq -n \
            --arg name "$agent_name" \
            --arg description "$description" \
            --arg prompt "$prompt" \
            --argjson resources "$resources" \
            --arg welcomeMessage "$welcome_message" \
            --argjson tools "$tools" \
            --argjson allowedTools "$allowed_tools" \
            --argjson toolsSettings "$tools_settings" \
            --argjson config "$root_config" \
            '
            {
                name: $name,
                description: $description,
                prompt: $prompt,
                resources: $resources,
                welcomeMessage: $welcomeMessage,
                tools: $tools,
                allowedTools: $allowedTools,
                toolsSettings: $toolsSettings
            } * (if ($config | type) == "object" then $config else {} end)
        ')

        echo "${output}" >"${output_file}"

        echo "Generated: $output_file"
    done
done

echo "Done! Generated all agents."
