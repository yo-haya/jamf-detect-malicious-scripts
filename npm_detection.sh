#!/bin/bash

# Jamf Extension Attribute: npm (Node.js) binary detection
# Detects installations of the npm executable statically across system and user paths.

declare -a findings

add_to_unique() {
    local new_bin="$1"
    if [[ -x "$new_bin" ]]; then
        local found=0
        for existing in "${findings[@]}"; do
            if [[ "$existing" == "$new_bin" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            findings+=("$new_bin")
        fi
    fi
}

shopt -s nullglob

# 1. System wide and Homebrew paths for npm executable
system_paths=(
    /usr/local/bin/npm
    /opt/homebrew/bin/npm
    /opt/workbrew/bin/npm
    /usr/bin/npm
)

for f in "${system_paths[@]}"; do
    add_to_unique "$f"
done

# 2. User specific paths for npm executable
for user_home in /Users/*; do
    [[ ! -d "$user_home" ]] && continue
    [[ "$user_home" == "/Users/Shared" ]] && continue
    
    user_paths=(
        "${user_home}"/.nvm/versions/node/*/bin/npm
        "${user_home}"/.nodenv/versions/*/bin/npm
        "${user_home}"/.npm-global/bin/npm
        "${user_home}"/.n/bin/npm
        "${user_home}"/.volta/tools/image/node/*/bin/npm
        "${user_home}"/Library/Caches/fnm_multishells/*/bin/npm
    )
    
    for f in "${user_paths[@]}"; do
        add_to_unique "$f"
    done
done

if [[ ${#findings[@]} -eq 0 ]]; then
    echo "<result>Not Installed</result>"
else
    # Join findings with semicolon separator
    result=$(IFS=';'; echo "${findings[*]}")
    echo "<result>${result}</result>"
fi

exit 0
