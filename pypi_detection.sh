#!/bin/bash

# Jamf Extension Attribute: PyPI (Python) site-packages detection
# Detects Python installations and lists their PyPI directories statically.
# (Avoids executing python binaries directly to prevent malicious code execution during audit)

declare -a findings

add_to_unique() {
    local new_dir="$1"
    if [[ -d "$new_dir" ]]; then
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
    fi
}

shopt -s nullglob

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
    add_to_unique "$d"
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
    )
    
    for d in "${user_paths[@]}"; do
        add_to_unique "$d"
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
