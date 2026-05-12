#!/bin/bash

# Jamf Extension Attribute: Malicious Scripts TanStack Detection
# Checks for specific malicious file paths and running processes, and returns the results.

declare -a findings

output=$(find /Users -maxdepth 5 -path '*/.claude/setup.mjs' -o -path '*/.vscode/setup.mjs' 2>/dev/null)
if [[ -n "$output" ]]; then
    findings+=("$output")
fi

output=$(find /Users -maxdepth 5 -path '*/.config/*gh-token-monitor*' 2>/dev/null)
if [[ -n "$output" ]]; then
    findings+=("$output")
fi

output=$(find /Users -maxdepth 5 -path '*/.local/bin/gh-token-monitor.sh' 2>/dev/null)
if [[ -n "$output" ]]; then
    findings+=("$output")
fi

output=$(find /tmp -name 'tmp.ts018051808.lock' 2>/dev/null)
if [[ -n "$output" ]]; then
    findings+=("$output")
fi

output=$(ps aux | grep -E 'tanstack_runner|router_runtime|gh-token-monitor' | grep -v grep)
if [[ -n "$output" ]]; then
    findings+=("$output")
fi

if [[ ${#findings[@]} -eq 0 ]]; then
    echo "<result>Not Detected</result>"
else
    result=$(IFS=$'\n'; echo "${findings[*]}")
    echo "<result>${result}</result>"
fi

exit 0
