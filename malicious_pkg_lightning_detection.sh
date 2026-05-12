#!/bin/bash

# Jamf Extension Attribute: lightning version detection
# Detects installations of lightning versions 2.6.2 or 2.6.3 statically.

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

# Function to check for lightning metadata in a site-packages dir
check_lightning() {
    local base_dir="$1"
    for version in "2.6.2" "2.6.3"; do
        if [[ -d "${base_dir}/lightning-${version}.dist-info" ]]; then
            add_to_unique "${base_dir}/lightning-${version}.dist-info"
        fi
    done
}

# 1. System wide and Homebrew paths
system_paths=(
    /Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/*/lib/python*/site-packages
    /Applications/Xcode.app/Contents/Developer/Library/Frameworks/Python3.framework/Versions/*/lib/python*/site-packages
    /Library/Python/*/lib/python/site-packages
    /opt/homebrew/lib/python*/site-packages
    /opt/homebrew/opt/python@*/Frameworks/Python.framework/Versions/*/lib/python*/site-packages
    /usr/local/lib/python*/site-packages
    /opt/workbrew/lib/python*/site-packages
)

for d in "${system_paths[@]}"; do
    if [[ -d "$d" ]]; then
        check_lightning "$d"
    fi
done

# 2. User specific paths
for user_home in /Users/*; do
    [[ ! -d "$user_home" ]] && continue
    [[ "$user_home" == "/Users/Shared" ]] && continue
    
    user_paths=(
        "${user_home}"/Library/Python/*/lib/python/site-packages
        "${user_home}"/.pyenv/versions/*/lib/python*/site-packages
        "${user_home}"/.pyenv/versions/*/envs/*/lib/python*/site-packages
        "${user_home}"/.asdf/installs/python/*/lib/python*/site-packages
        "${user_home}"/miniconda3/envs/*/lib/python*/site-packages
        "${user_home}"/miniconda3/lib/python*/site-packages
        "${user_home}"/opt/anaconda3/envs/*/lib/python*/site-packages
        "${user_home}"/opt/anaconda3/lib/python*/site-packages
        "${user_home}"/anaconda3/envs/*/lib/python*/site-packages
        "${user_home}"/anaconda3/lib/python*/site-packages
        "${user_home}"/.conda/envs/*/lib/python*/site-packages
        "${user_home}"/.local/share/uv/tools/*/lib/python*/site-packages
        "${user_home}"/.local/share/uv/python/*/lib/python*/site-packages
    )
    
    for d in "${user_paths[@]}"; do
        if [[ -d "$d" ]]; then
            check_lightning "$d"
        fi
    done

    # Search for local .venv and venv directories within a limited depth
    while IFS= read -r -d '' venv_dir; do
        for sp in "$venv_dir"/lib/python*/site-packages; do
            if [[ -d "$sp" ]]; then
                check_lightning "$sp"
            fi
        done
    done < <(find "$user_home" -maxdepth 4 -type d \( -name ".venv" -o -name "venv" \) -print0 2>/dev/null)
done

if [[ ${#findings[@]} -eq 0 ]]; then
    echo "<result>Not Detected</result>"
else
    # Join findings with semicolon separator
    result=$(IFS=';'; echo "${findings[*]}")
    echo "<result>${result}</result>"
fi

exit 0
