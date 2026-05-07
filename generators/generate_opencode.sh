#!/bin/bash
set -euo pipefail

# ============================================================================
# generate_opencode.sh — Generate agent configs for OpenCode
#
# Usage:
#   ./generate_opencode.sh --output DIR --agents-dir DIR --agents-json FILE --skills-dir DIR
#
# Options:
#   --output          Output directory for generated agent files (required)
#   --agents-dir      Directory containing generic agent definitions (.json files)
#   --agents-json     Path to agents registry JSON file (required)
#   --skills-dir      Path to skills directory (required)
#
# The tool mapping file (cli-mapping.json) is always loaded from <repo>/mappings/
# regardless of --agents-dir or --agents-json.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAPPING_FILE="${SCRIPT_DIR}/../mappings/cli-mapping.json"
OUTPUT_DIR=""
AGENTS_DIR=""
AGENTS_JSON=""
SKILLS_DIR=""

usage() {
    echo "Usage: $0 --output DIR --agents-dir DIR --agents-json FILE --skills-dir DIR"
    echo ""
    echo "Options:"
    echo "  --output          Output directory for generated agent files (required)"
    echo "  --agents-dir      Directory containing generic agent definitions (.json files)"
    echo "  --agents-json     Path to agents registry JSON file (required)"
    echo "  --skills-dir      Path to skills directory (required)"
    echo "  --help, -h        Show this help message"
}

exit_usage() {
    usage
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
            exit_usage
        fi
        ;;
    --agents-dir)
        if [[ -n "$2" && "$2" != --* ]]; then
            AGENTS_DIR="$2"
            shift 2
        else
            echo "Error: --agents-dir requires a value."
            exit_usage
        fi
        ;;
    --agents-json)
        if [[ -n "$2" && "$2" != --* ]]; then
            AGENTS_JSON="$2"
            shift 2
        else
            echo "Error: --agents-json requires a value."
            exit_usage
        fi
        ;;
    --skills-dir)
        if [[ -n "$2" && "$2" != --* ]]; then
            SKILLS_DIR="$2"
            shift 2
        else
            echo "Error: --skills-dir requires a value."
            exit_usage
        fi
        ;;
    --help | -h)
        usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        exit_usage
        ;;
    esac
done

# Validate required args
if [ -z "${OUTPUT_DIR}" ]; then
    echo "Error: --output DIR is required."
    exit_usage
fi
if [ -z "${AGENTS_DIR}" ]; then
    echo "Error: --agents-dir DIR is required."
    exit_usage
fi
if [ -z "${AGENTS_JSON}" ]; then
    echo "Error: --agents-json FILE is required."
    exit_usage
fi
if [ -z "${SKILLS_DIR}" ]; then
    echo "Error: --skills-dir DIR is required."
    exit_usage
fi

# Validate that key input files exist
if [ ! -f "${MAPPING_FILE}" ]; then
    echo "Error: Mapping file not found at ${MAPPING_FILE}" >&2
    exit 1
fi
if [ ! -f "${AGENTS_JSON}" ]; then
    echo "Error: Agents JSON file not found at ${AGENTS_JSON}" >&2
    exit 1
fi

if ! command -v jq &>/dev/null; then
    echo "Error: jq not found" >&2
    exit 1
fi

echo "Generating OpenCode agents to ${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Iterate over themes and professions
THEMES=$(jq -r 'keys[]' "$AGENTS_JSON")

for theme in $THEMES; do
    PROFESSIONS=$(jq -r ".[\"$theme\"] | keys[]" "$AGENTS_JSON")
    for profession in $PROFESSIONS; do
        # Source file for this profession
        generic_agent_file="$AGENTS_DIR/agent-$profession.json"

        if [ ! -f "$generic_agent_file" ]; then
            echo "Warning: Generic agent $generic_agent_file not found, skipping $theme-$profession" >&2
            continue
        fi

        # Read registry info
        description=$(jq -r --arg t "$theme" --arg p "$profession" '.[$t][$p].description' "$AGENTS_JSON")
        personaFile=$(jq -r --arg t "$theme" --arg p "$profession" '.[$t][$p].personaFile' "$AGENTS_JSON")

        # Read and substitute {{THEME}} in the generic agent
        agent_json=$(jq -R -s --arg theme "$theme" 'gsub("{{THEME}}"; $theme) | fromjson' "$generic_agent_file")

        # Read skills.default from the generic agent
        skills_default=$(echo "$agent_json" | jq -r '.skills.default // "ask"')

        # Scan skills directory for this profession's skills
        skill_dir="$SKILLS_DIR/$profession"
        if [ -d "$skill_dir" ]; then
            skill_names_json=$(find "$skill_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort | jq -R . | jq -s .)
        else
            skill_names_json="[]"
        fi

        # Build the output using jq
        output=$(
            jq -n \
                --argjson agent "$agent_json" \
                --arg theme "$theme" \
                --arg profession "$profession" \
                --arg description "$description" \
                --arg personaFile "$personaFile" \
                --argjson skill_names "$skill_names_json" \
                --arg skills_default "$skills_default" \
                --slurpfile mapping "${MAPPING_FILE}" \
                '
                # --- Mapping helpers using cli-mapping.json ---

                # Get OpenCode tool name from mapping (opencode field)
                def get_opencode_name($k):
                    if ($mapping[0].tools | has($k)) and ($mapping[0].tools[$k] | has("opencode")) then
                        if ($mapping[0].tools[$k].opencode | type) == "string" then
                            $mapping[0].tools[$k].opencode
                        else
                            $k
                        end
                    else $k end;

                # Check if tool should be included in OpenCode output
                # Include if opencode field is truthy (string or true), exclude if false or absent
                def is_opencode_tool($k):
                    if ($mapping[0].tools | has($k)) then
                        if ($mapping[0].tools[$k] | has("opencode")) then
                            if ($mapping[0].tools[$k].opencode | type) == "string" then true
                            else $mapping[0].tools[$k].opencode == true end
                        else false end
                    else true end;

                # Check if config key should be promoted to OpenCode output
                def is_opencode_config($k):
                    if ($mapping[0].config | has($k)) and ($mapping[0].config[$k] | has("opencode")) then
                        $mapping[0].config[$k].opencode == true
                    else false end;

                # Transform tool value: remove config key, rename default to *
                def transform_value:
                    if type == "object" then
                        to_entries |
                        map(if .key == "config" then empty
                            elif .key == "default" then .key = "*"
                            else . end) |
                        from_entries |
                        if (. | keys | length) == 1 then .["*"]
                        else . end
                    else . end;

                # --- Build tools permission ---
                # Exclude default entry, filter to opencode-enabled tools,
                # translate names via mapping, transform values
                ([ $agent.tools | to_entries[] |
                    select(.key != "default") |
                    select(is_opencode_tool(.key)) |
                    .key as $k |
                    {(get_opencode_name($k)): (.value | transform_value)}
                ] | add // {}) as $tp |

                # Top-level default permission from tools.default
                ($agent.tools.default // "deny") as $tp_default |

                # --- Build external_directory ---
                # Base set: ask for everything except opencode config dir
                # When default is "deny" (restrictive), also extract path-based
                # allow entries from write and edit tools
                (["write", "edit"] as $ext_tools |
                $ext_tools | map(
                    . as $tool |
                    select($agent.tools | has($tool)) |
                    $agent.tools[$tool] as $v |
                    if ($v | type) == "object" then
                        [$v | to_entries[] |
                            select(.key != "default" and .key != "config" and .value == "allow") |
                            .key]
                    else [] end
                ) | flatten | unique) as $write_edit_paths |

                ($tp_default != "allow") as $restrictive |

                ({"external_directory": (
                    {"*": "ask", "~/.config/opencode/**": "allow"} +
                    (if $restrictive then
                        reduce $write_edit_paths[] as $p ({}; . + {($p): "allow"})
                    else {} end)
                )}) as $ext |

                # --- Skill permission ---
                (
                    {"*": $skills_default} + (($skill_names | map({(.): "allow"}) | add) // {})
                ) as $skill_obj |
                {"skill": $skill_obj} as $sk |

                # --- Assemble permission: * → external_directory → tools → skill ---
                {
                    "*": $tp_default
                } + $ext + $tp + $sk |

                # --- Build top-level config fields using mapping (opencode: true) ---
                (if ($agent.config | type) == "object" then
                    [$agent.config | to_entries[] |
                        select(is_opencode_config(.key))
                    ] | from_entries
                else {} end) as $cfg |

                # Pre-compute compound values to avoid inline + in object literals
                ($theme + "-" + $profession) as $agent_name |
                ($agent.profession // $profession) as $agent_profession |
                ("{file:~/.config/opencode/professions/" + $agent_profession + ".md}{file:~/.config/opencode/personas/" + $theme + "/" + $personaFile + "}") as $prompt |

                # Build the output object — description, config fields, prompt, permission
                {
                    $agent_name: (
                        {
                            "description": $description
                        } + $cfg + {
                            "prompt": $prompt,
                            "permission": .
                            }
                    )
                }
            '
        )

        output_file="$OUTPUT_DIR/${theme}-${profession}.json"
        echo "$output" >"$output_file"
        echo "Generated: $output_file"
    done
done

echo "Done! Generated all OpenCode agents."
