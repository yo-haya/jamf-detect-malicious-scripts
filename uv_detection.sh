#!/bin/bash

# Jamf Extension Attribute: uv Python environment detection
# Detects installations of Python site-packages managed by uv statically.
# Filters standard venv/.venv to only include those created/managed by uv.

declare -a findings

add_to_unique() {
    local new_dir="$1"
    if [[ -d "$new_dir" ]]; then
        local found=0
        for existing in "${findings[@]}"; do
            [[ "$existing" == "$new_dir" ]] && found=1 && break
        done
        [[ $found -eq 0 ]] && findings+=("$new_dir")
    fi
}

shopt -s nullglob

# Function to check if a venv was installed/managed by uv
# Criteria: The parent directory contains uv.lock OR
# any dist-info/INSTALLER inside site-packages contains "uv"
is_uv_managed() {
    local sp_dir="$1"
    # sp_dir path is typically: /.../project/.venv/lib/pythonX.Y/site-packages
    # So venv location is 3 dirs up: /.../project/.venv
    local venv_dir=$(dirname $(dirname $(dirname "$sp_dir")))
    local project_dir=$(dirname "$venv_dir")
    
    # 1. Check for uv.lock in project directory
    if [[ -f "${project_dir}/uv.lock" ]]; then
        return 0
    fi
    
    # 2. Check INSTALLER files in site-packages
    # If any package was installed by uv, its INSTALLER file contains "uv"
    for installer_file in "${sp_dir}"/*.dist-info/INSTALLER; do
        if grep -q -m 1 "^uv$" "$installer_file" 2>/dev/null; then
            return 0
        fi
    done
    
    return 1
}

# Search user directories for uv-managed environments
for user_home in /Users/*; do
    [[ ! -d "$user_home" ]] && continue
    [[ "$user_home" == "/Users/Shared" ]] && continue
    
    user_paths=(
        # uv tool environments (these are inherently managed by uv)
        "${user_home}"/.local/share/uv/tools/*/lib/python*/site-packages
        
        # uv python environments
        "${user_home}"/.local/share/uv/python/*/lib/python*/site-packages
    )
    
    for d in "${user_paths[@]}"; do
        add_to_unique "$d"
    done

    # Search for local .venv and venv directories within a limited depth
    while IFS= read -r -d '' venv_dir; do
        for sp in "$venv_dir"/lib/python*/site-packages; do
            if [[ -d "$sp" ]]; then
                # Only add if it's confirmed as uv-managed
                if is_uv_managed "$sp"; then
                    add_to_unique "$sp"
                fi
            fi
        done
    done < <(find "$user_home" -maxdepth 4 -type d \( -name ".venv" -o -name "venv" \) -print0 2>/dev/null)
done

if [[ ${#findings[@]} -eq 0 ]]; then
    echo "<result>Not Installed</result>"
else
    # Join findings with semicolon separator
    result=$(IFS=';'; echo "${findings[*]}")
    echo "<result>${result}</result>"
fi

exit 0
