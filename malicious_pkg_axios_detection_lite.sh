#!/bin/bash

# Jamf Extension Attribute: axios malicious version detection
# Detects installations of axios versions 1.14.1 or 0.30.4 statically.

declare -a findings

add_to_unique() {
    local new_dir="$1"
    local found=0
    for existing in "${findings[@]}"; do
        if [[ "$existing" == "$new_dir" ]]; then
            found=1
            break
        fi
    done
    if [[ $found -eq 0 ]]; then
        findings+=("$new_dir")
    fi
}

shopt -s nullglob

# Function to check for axios malicious versions in a node_modules dir
check_malicious_packages() {
    local base_dir="$1"
    
    # Check axios
    local axios_json="${base_dir}/axios/package.json"
    if [[ -f "$axios_json" ]]; then
        local axios_version
        axios_version=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"(1\.14\.1|0\.30\.4)"' "$axios_json" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        if [[ -n "$axios_version" ]]; then
            add_to_unique "${base_dir}/axios (${axios_version})"
        fi
    fi

}

# 1. System wide and Homebrew paths
system_paths=(
    /usr/local/lib/node_modules
    /opt/homebrew/lib/node_modules
    /opt/homebrew/opt/node@*/lib/node_modules
    /opt/workbrew/lib/node_modules
)

for d in "${system_paths[@]}"; do
    if [[ -d "$d" ]]; then
        check_malicious_packages "$d"
    fi
done

# 2. User specific paths
for user_home in /Users/*; do
    [[ ! -d "$user_home" ]] && continue
    [[ "$user_home" == "/Users/Shared" ]] && continue
    
    user_paths=(
        "${user_home}"/.nvm/versions/node/*/lib/node_modules
        "${user_home}"/.nodenv/versions/*/lib/node_modules
        "${user_home}"/.npm-global/lib/node_modules
        "${user_home}"/.n/lib/node_modules
        "${user_home}"/Library/Caches/fnm_multishells/*/lib/node_modules
        "${user_home}"/.volta/tools/image/node/*/lib/node_modules
    )
    
    for d in "${user_paths[@]}"; do
        if [[ -d "$d" ]]; then
            check_malicious_packages "$d"
        fi
    done

    # Search for local node_modules directories within a limited depth
    while IFS= read -r -d '' nm_dir; do
        check_malicious_packages "$nm_dir"
    done < <(find "$user_home" -maxdepth 4 -type d -name "node_modules" -print0 2>/dev/null)
done

if [[ ${#findings[@]} -eq 0 ]]; then
    echo "<result>Not Detected</result>"
else
    # Join findings with semicolon separator
    result=$(IFS=';'; echo "${findings[*]}")
    echo "<result>${result}</result>"
fi

exit 0
