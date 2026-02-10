# Create a GitHub issue (or develop an existing one) and set up a worktree
# Usage: ghwt [-c] [-i <number>] "Issue title"
ghwt() {
  local base_branch="" issue_number=""

  # Parse flags
  while [[ "$1" == -* ]]; do
    case "$1" in
      -c|--current)
        base_branch=$(git branch --show-current)
        shift
        ;;
      -i|--issue)
        issue_number="$2"
        shift 2
        ;;
      -h|--help)
        echo "Usage: ghwt [-c] [-i <number>] \"Issue title\""
        echo "  -c, --current   Branch from current branch instead of main"
        echo "  -i, --issue N   Develop an existing issue instead of creating one"
        echo "  -h, --help      Show this help"
        return 0
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: ghwt [-c] [-i <number>] \"Issue title\""
        return 1
        ;;
    esac
  done

  # If no existing issue, create one from title
  if [[ -z "$issue_number" ]]; then
    local title="$1"
    if [[ -z "$title" ]]; then
      echo "Usage: ghwt [-c] [-i <number>] \"Issue title\""
      return 1
    fi

    local issue_url
    issue_url=$(gh issue create --title "$title" --body "" 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "Failed to create issue: $issue_url"
      return 1
    fi

    issue_number=$(echo "$issue_url" | grep -oE '[0-9]+$')
    echo "Created issue #$issue_number: $issue_url"
  else
    echo "Developing existing issue #$issue_number"
  fi

  # Use gh issue develop to create a branch
  local develop_output base_arg=""
  [[ -n "$base_branch" ]] && base_arg="--base $base_branch"
  develop_output=$(gh issue develop "$issue_number" $base_arg 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Failed to create branch: $develop_output"
    return 1
  fi

  # Extract branch name from the URL line (format: "github.com/owner/repo/tree/branch-name")
  local branch_name
  branch_name=$(echo "$develop_output" | grep '/tree/' | head -1 | grep -oE '[^/]+$')
  echo "Created branch: $branch_name"

  # Fetch the new branch
  git fetch origin "$branch_name"

  # Ensure worktrees directory exists
  mkdir -p ~/.claude/worktrees

  # Get repo name for worktree folder
  local repo_name
  repo_name=$(basename "$(git rev-parse --show-toplevel)")
  local worktree_path="$HOME/.claude/worktrees/${repo_name}-${issue_number}"

  # Create the worktree
  git worktree add "$worktree_path" "$branch_name"

  echo "Worktree created at: $worktree_path"

  # Copy .env.local if it exists
  local repo_root
  repo_root=$(git rev-parse --show-toplevel)
  [[ -f "$repo_root/.env.local" ]] && cp "$repo_root/.env.local" "$worktree_path/.env.local"

  # Open Cursor and arrange Left & Right (Cursor left, Ghostty right)
  open -a "Cursor" "$worktree_path"
  sleep 0.8
  osascript -e 'tell application "Cursor" to activate' \
    -e 'delay 0.2' \
    -e 'tell application "System Events" to key code 123 using {control down, shift down, command down}'

  # cd and start claude
  cd "$worktree_path"
  claude
}

# Remove a worktree created by ghwt
# Usage: ghwtrm <issue-number>
ghwtrm() {
  if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: ghwtrm <issue-number>"
    echo "  Remove a worktree created by ghwt for the given issue"
    return 0
  fi

  local issue_number="$1"

  if ! [[ "$issue_number" =~ ^[0-9]+$ ]]; then
    echo "Error: Issue number must be numeric"
    return 1
  fi

  local repo_name
  repo_name=$(basename "$(git config --get remote.origin.url 2>/dev/null | sed 's/\.git$//')")
  if [[ -z "$repo_name" ]]; then
    echo "Error: Not in a git repository"
    return 1
  fi

  local worktree_path="$HOME/.claude/worktrees/${repo_name}-${issue_number}"

  if [[ ! -d "$worktree_path" ]]; then
    echo "Error: No worktree found at $worktree_path"
    return 1
  fi

  git worktree remove "$worktree_path" --force 2>/dev/null || git worktree remove "$worktree_path"
  if [[ $? -ne 0 ]]; then
    echo "Failed to remove worktree. Close any open files in Cursor and try again."
    return 1
  fi

  [[ -d "$worktree_path" ]] && rm -rf "$worktree_path"

  echo "Removed worktree: $worktree_path"
}

# Open a new Ghostty window in the current directory (uses existing instance if running)
# Usage: ght
ght() {
  local dir
  dir=$(pwd)
  if pgrep -i ghostty >/dev/null 2>&1; then
    (osascript -e 'on run {thePath}' \
      -e 'tell application "Ghostty" to activate' \
      -e 'delay 0.5' \
      -e 'tell application "System Events" to keystroke "n" using command down' \
      -e 'delay 0.8' \
      -e 'tell application "System Events" to keystroke "cd " & (quoted form of thePath)' \
      -e 'tell application "System Events" to key code 36' \
      -e 'end run' -- "$dir" &)
  else
    open -a Ghostty --args --working-directory="$dir"
  fi
}

# Create a worktree for an existing branch (without GitHub issue)
# Usage: wt <branch-name>
wt() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    echo "Usage: wt <branch-name>"
    echo "  Create a worktree for an existing branch"
    return 0
  fi

  local branch_name="$1"

  # Check if branch exists locally
  if ! git show-ref --verify --quiet refs/heads/"$branch_name"; then
    # Branch doesn't exist locally, check remote
    if ! git show-ref --verify --quiet refs/remotes/origin/"$branch_name"; then
      echo "Error: Branch '$branch_name' does not exist locally or remotely"
      return 1
    fi
    
    # Fetch the branch from remote
    echo "Fetching branch '$branch_name' from remote..."
    git fetch origin "$branch_name"
    if [[ $? -ne 0 ]]; then
      echo "Failed to fetch branch '$branch_name' from remote"
      return 1
    fi
  fi

  # Ensure worktrees directory exists
  mkdir -p ~/.claude/worktrees

  # Get repo name for worktree folder
  local repo_name
  repo_name=$(basename "$(git rev-parse --show-toplevel)")
  
  # Sanitize branch name for filesystem (replace / and other invalid chars with -)
  local sanitized_branch_name
  sanitized_branch_name=$(echo "$branch_name" | sed 's/[\/<>:"|?*]/-/g')
  
  local worktree_path="$HOME/.claude/worktrees/${repo_name}-${sanitized_branch_name}"

  # Check if worktree already exists
  if [[ -d "$worktree_path" ]]; then
    echo "Worktree already exists at: $worktree_path"
    echo "Opening existing worktree..."
  else
    # Create the worktree
    git worktree add "$worktree_path" "$branch_name"
    if [[ $? -ne 0 ]]; then
      echo "Failed to create worktree"
      return 1
    fi
    echo "Worktree created at: $worktree_path"

    # Copy .env.local if it exists
    local repo_root
    repo_root=$(git rev-parse --show-toplevel)
    [[ -f "$repo_root/.env.local" ]] && cp "$repo_root/.env.local" "$worktree_path/.env.local"
  fi

  # Open Cursor and arrange Left & Right (Cursor left, Ghostty right)
  open -a "Cursor" "$worktree_path"
  sleep 0.8
  osascript -e 'tell application "Cursor" to activate' \
    -e 'delay 0.2' \
    -e 'tell application "System Events" to key code 123 using {control down, shift down, command down}'

  # cd and start claude
  cd "$worktree_path"
  claude
}
