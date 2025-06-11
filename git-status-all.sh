#!/bin/bash

verbose_mode=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)
            verbose_mode=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

find . -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir; do
    if [ -d "$dir/.git" ]; then
        (
            cd "$dir"
            
            # Check for uncommitted changes
            uncommitted_changes=$(git status --porcelain)
            
            # Check if ahead/behind upstream
            upstream_status=""
            branch=$(git branch --show-current 2>/dev/null)
            if [ -n "$branch" ]; then
                upstream_status=$(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
            fi
            
            # Determine if we should show this repo
            show_repo=0
            if [[ $verbose_mode -eq 1 ]]; then
                show_repo=1
            elif [ -n "$uncommitted_changes" ]; then
                show_repo=1
            elif [ -n "$upstream_status" ]; then
                ahead=$(echo $upstream_status | awk '{print $2}')
                behind=$(echo $upstream_status | awk '{print $1}')
                [[ $ahead -gt 0 || $behind -gt 0 ]] && show_repo=1
            fi
            
            # Show repository status if needed
            if [[ $show_repo -eq 1 ]]; then
                echo -e "\n\033[1;34mRepository: ${dir#./}\033[0m"
                git status
                echo "------------------------------"
            fi
        )
    fi
done
