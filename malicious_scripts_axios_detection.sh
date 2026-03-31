#!/bin/bash

# Jamf Extension Attribute: com.apple.act.mond detection
# Detects the existence of /Library/Caches/com.apple.act.mond by running ls -la

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

TARGET_FILE="/Library/Caches/com.apple.act.mond"

# Check if the file (or directory) exists
if [[ -e "$TARGET_FILE" ]]; then
    # Execute ls -la as requested and capture the output
    ls_output=$(ls -la "$TARGET_FILE" 2>/dev/null)
    if [[ -n "$ls_output" ]]; then
        add_to_unique "$ls_output"
    else
        add_to_unique "$TARGET_FILE"
    fi
fi

if [[ ${#findings[@]} -eq 0 ]]; then
    echo "<result>Not Detected</result>"
else
    # Join findings with semicolon separator (though there is only one in this case)
    result=$(IFS=';'; echo "${findings[*]}")
    echo "<result>${result}</result>"
fi

exit 0
