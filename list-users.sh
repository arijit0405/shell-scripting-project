#!/bin/bash

# GitHub API base URL
API_URL="https://api.github.com"

# GitHub username and personal access token from environment variables
USERNAME=$username
TOKEN=$token

# Check for required inputs
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <repo_owner> <repo_name> <access_level>"
    echo "Access level must be one of: read, write, admin"
    exit 1
fi

# Input arguments
REPO_OWNER=$1       # e.g., arijit0405
REPO_NAME=$2        # e.g., my-repo
ACCESS_LEVEL=$3     # read / write / admin

# Function to make a GET request to GitHub API with authentication
function github_api_get {
    local endpoint="$1"
    local url="${API_URL}/${endpoint}"
    curl -s -u "${USERNAME}:${TOKEN}" "$url"
}

# Function to determine the right permission filter based on access level
function get_permission_filter {
    case "$ACCESS_LEVEL" in
        read)
            echo '.permissions.pull == true and .permissions.push == false and .permissions.admin == false'
            ;;
        write)
            echo '.permissions.push == true and .permissions.admin == false'
            ;;
        admin)
            echo '.permissions.admin == true'
            ;;
        *)
            echo "Invalid access level: $ACCESS_LEVEL"
            exit 2
            ;;
    esac
}

# Function to list collaborators with the chosen permission level
function list_collaborators {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators"
    local filter="$(get_permission_filter)"

    collaborators=$(github_api_get "$endpoint" | jq -r ".[] | select(${filter}) | .login")

    if [[ -z "$collaborators" ]]; then
        echo "No users with '$ACCESS_LEVEL' access found for ${REPO_OWNER}/${REPO_NAME}."
    else
        echo "Users with '$ACCESS_LEVEL' access to ${REPO_OWNER}/${REPO_NAME}:"
        echo "$collaborators"
    fi
}

# Run the script
echo "Fetching collaborators with '$ACCESS_LEVEL' access to $REPO_OWNER/$REPO_NAME..."
list_collaborators
