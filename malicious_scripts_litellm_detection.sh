#!/bin/bash

# Jamf Extension Attribute: sysmon malicious files detection
# Detects installations of malicious sysmon.py (by SHA256 hash) and sysmon.service

declare -a findings

add_to_unique() {
    local new_item="$1"
    local found=0
    for existing in "${findings[@]}"; do
        if [[ "$existing" == "$new_item" ]]; then
            found=1
            break
        fi
    done
    if [[ $found -eq 0 ]]; then
        findings+=("$new_item")
    fi
}

TARGET_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

# Search user directories
for user_home in /Users/*; do
    [[ ! -d "$user_home" ]] && continue
    [[ "$user_home" == "/Users/Shared" ]] && continue
    
    # 1. Check for ~/.config/sysmon/sysmon.py
    sysmon_py="${user_home}/.config/sysmon/sysmon.py"
    if [[ -f "$sysmon_py" ]]; then
        # Calculate SHA256 hash
        # Use shasum -a 256 which is standard on macOS
        current_hash=$(shasum -a 256 "$sysmon_py" 2>/dev/null | awk '{print $1}')
        if [[ "$current_hash" == "$TARGET_HASH" ]]; then
            add_to_unique "$sysmon_py"
        fi
    fi
    
    # 2. Check for ~/.config/systemd/user/sysmon.service
    sysmon_service="${user_home}/.config/systemd/user/sysmon.service"
    if [[ -f "$sysmon_service" ]]; then
        add_to_unique "$sysmon_service"
    fi
done

if [[ ${#findings[@]} -eq 0 ]]; then
    echo "<result>Not Installed</result>"
else
    # Join findings with semicolon separator
    result=$(IFS=';'; echo "${findings[*]}")
    echo "<result>${result}</result>"
fi

exit 0
