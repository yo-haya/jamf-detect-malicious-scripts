#!/bin/bash

# Jamf Extension Attribute: axios malicious version detection (npm ls)
# Detects installations of axios versions 1.14.1 or 0.30.4 using the npm ls command.

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

# 1. First, check if npm is installed and get its path
NPM_BIN=""
if command -v npm &> /dev/null; then
    NPM_BIN=$(command -v npm)
else
    # Fallback to check common paths if not in PATH (Jamf runs as root and may lack user PATHs)
    for p in /usr/local/bin/npm /opt/homebrew/bin/npm /usr/bin/npm; do
        if [[ -x "$p" ]]; then
            NPM_BIN="$p"
            break
        fi
    done
fi

if [[ -z "$NPM_BIN" ]]; then
    # npm is not installed, so no npm packages can be detected
    echo "<result>Not Detected</result>"
    exit 0
fi

# Function to check for malicious package versions using npm ls
check_npm_packages() {
    local project_dir="$1"
    
    # Go to the project directory to run npm ls
    if cd "$project_dir" 2>/dev/null; then
        # Run npm ls using the detected exact path and capture output
        local ls_output
        ls_output=$("$NPM_BIN" ls axios --all 2>/dev/null || "$NPM_BIN" ls axios 2>/dev/null)
        
        # Check for axios malicious versions
        if echo "$ls_output" | grep -qE 'axios@(1\.14\.1|0\.30\.4)'; then
            # Extract the actual version for output clarity
            local axios_version
            axios_version=$(echo "$ls_output" | grep -oE 'axios@(1\.14\.1|0\.30\.4)' | head -n 1 | cut -d'@' -f2)
            add_to_unique "${project_dir}/node_modules/axios (${axios_version})"
        fi


    fi
}

shopt -s nullglob

# 2. System wide and Homebrew Global npm checks
global_ls=$("$NPM_BIN" ls -g axios 2>/dev/null)
if echo "$global_ls" | grep -qE 'axios@(1\.14\.1|0\.30\.4)'; then
    add_to_unique "Global NPM: axios"
fi

# 3. User specific project paths
for user_home in /Users/*; do
    [[ ! -d "$user_home" ]] && continue
    [[ "$user_home" == "/Users/Shared" ]] && continue
    
    # We search for directories containing node_modules and use their parent dir as the project_dir.
    while IFS= read -r -d '' nm_dir; do
        project_dir=$(dirname "$nm_dir")
        if [[ -f "${project_dir}/package.json" ]]; then
            check_npm_packages "$project_dir"
        fi
    done < <(find "$user_home" -maxdepth 5 -type d -name "node_modules" -print0 2>/dev/null)
done

if [[ ${#findings[@]} -eq 0 ]]; then
    echo "<result>Not Detected</result>"
else
    # Join findings with semicolon separator
    result=$(IFS=';'; echo "${findings[*]}")
    echo "<result>${result}</result>"
fi

exit 0
