#!/bin/bash

# git-revive - Restore Git tracking to a directory that lost its .git folder
# Usage: git-revive <remote-url> <branch> <target-directory>

set -e  # Exit on any error

# Function to display usage
usage() {
    echo "Usage: $0 <remote-url> <branch> <target-directory>"
    echo ""
    echo "Examples:"
    echo "  $0 git@github.com:user/repo.git main ./my-project"
    echo "  $0 https://github.com/user/repo.git develop ./my-project"
    echo ""
    echo "This script will:"
    echo "  1. Clone the repository to a temporary directory"
    echo "  2. Copy the .git folder to your target directory"
    echo "  3. Preserve all your local changes"
    echo "  4. Clean up temporary files"
    exit 1
}

# Function to clean up temporary directory
cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo "Cleaning up temporary directory..."
        rm -rf "$TEMP_DIR"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Check arguments
if [ $# -ne 3 ]; then
    echo "Error: Invalid number of arguments"
    usage
fi

REMOTE_URL="$1"
BRANCH="$2"
TARGET_DIR="$3"

# Validate inputs
if [ -z "$REMOTE_URL" ] || [ -z "$BRANCH" ] || [ -z "$TARGET_DIR" ]; then
    echo "Error: All arguments are required"
    usage
fi

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Check if target directory already has a .git folder
if [ -d "$TARGET_DIR/.git" ]; then
    echo "Warning: Target directory already has a .git folder"
    read -p "Do you want to replace it? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled"
        exit 1
    fi
    echo "Backing up existing .git folder to .git.backup..."
    mv "$TARGET_DIR/.git" "$TARGET_DIR/.git.backup"
fi

# Convert target directory to absolute path
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)

echo "Git Revive Starting..."
echo "Remote URL: $REMOTE_URL"
echo "Branch: $BRANCH"
echo "Target Directory: $TARGET_DIR"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Clone the repository
echo "Cloning repository..."
if ! git clone --branch "$BRANCH" --single-branch "$REMOTE_URL" "$TEMP_DIR/repo"; then
    echo "Error: Failed to clone repository"
    echo "Please check:"
    echo "  - Remote URL is correct and accessible"
    echo "  - Branch '$BRANCH' exists"
    echo "  - You have proper authentication (SSH keys, tokens, etc.)"
    exit 1
fi

# Copy .git folder to target directory
echo "Copying .git folder to target directory..."
cp -r "$TEMP_DIR/repo/.git" "$TARGET_DIR/"

# Change to target directory for git operations
cd "$TARGET_DIR"

# Update the working directory to match the repository state
echo "Updating Git index..."
git reset --mixed HEAD

# Show status
echo ""
echo "Git revive completed successfully!"
echo ""
echo "Repository status:"
git status --short

echo ""
echo "Summary:"
echo "  - Git tracking has been restored"
echo "  - Your local changes are preserved"
echo "  - Run 'git status' to see what has changed"
echo "  - Run 'git diff' to see your modifications"
echo ""

# Optional: Ask if user wants to see the diff
read -p "Would you like to see your local changes? (y/N): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Your local changes:"
    git diff --stat
    echo ""
    read -p "Show detailed diff? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git diff
    fi
fi
