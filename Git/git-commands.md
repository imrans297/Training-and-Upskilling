# Git Commands Reference - Basic to Advanced

## Basic Git Commands

### Setup & Configuration
```bash
git config --global user.name "Your Name"     # Set your name globally
git config --global user.email "your.email@example.com"  # Set your email globally
git config --list                            # View all configuration settings
```
**When to use:** First-time Git setup on a new machine or when changing user identity.

### Repository Initialization
```bash
git init                                      # Initialize new Git repository in current directory
git clone <repository-url>                   # Clone remote repository to local machine
git clone <repository-url> <directory-name>  # Clone repository into specific directory
```
**When to use:** Starting a new project (init) or working on existing project (clone).

### Basic Workflow
```bash
git status                                    # Check current status of working directory
git add <file>                               # Stage specific file for commit
git add .                                    # Stage all changes for commit
git commit -m "commit message"               # Commit staged changes with message
git push                                     # Upload commits to remote repository
git pull                                     # Download and merge changes from remote
```
**When to use:** Daily development workflow - check status, stage changes, commit, and sync with remote.

## Intermediate Git Commands

### Branching
```bash
git branch                                   # List all local branches
git branch <branch-name>                     # Create new branch
git checkout <branch-name>                   # Switch to existing branch
git checkout -b <new-branch>                 # Create and switch to new branch
git switch <branch-name>                     # Modern way to switch branches
git switch -c <new-branch>                   # Modern way to create and switch
git merge <branch-name>                      # Merge specified branch into current
git branch -d <branch-name>                  # Delete merged branch
```
**When to use:** Feature development, bug fixes, or any parallel work streams.

### Remote Operations
```bash
git remote -v                                # View remote repositories
git remote add origin <url>                  # Add remote repository
git push -u origin <branch>                  # Push branch and set upstream
git fetch                                    # Download changes without merging
git pull origin <branch>                     # Pull specific branch from remote
```
**When to use:** Setting up remotes, syncing with team, or managing multiple repositories.

### History & Logs
```bash
git log                                      # View commit history
git log --oneline                            # Compact one-line commit history
git log --graph                              # Visual branch graph
git show <commit-hash>                       # Show specific commit details
git diff                                     # Show unstaged changes
git diff <file>                              # Show changes in specific file
```
**When to use:** Reviewing project history, debugging, or understanding code changes.

## Advanced Git Commands

### Stashing
```bash
git stash                                    # Temporarily save uncommitted changes
git stash save "message"                     # Stash with descriptive message
git stash list                               # List all stashes
git stash pop                                # Apply and remove latest stash
git stash apply                              # Apply stash without removing
git stash drop                               # Delete specific stash
```
**When to use:** Switching branches with uncommitted work or temporary code storage.

### Reset & Revert
```bash
git reset --soft HEAD~1                      # Undo commit, keep changes staged
git reset --mixed HEAD~1                     # Undo commit, unstage changes
git reset --hard HEAD~1                      # Undo commit, discard all changes
git revert <commit-hash>                     # Create new commit that undoes changes
```
**When to use:** Fixing mistakes in commits or safely undoing changes in shared repositories.

### Rebasing
```bash
git rebase <branch>                          # Replay commits on top of another branch
git rebase -i HEAD~3                         # Interactive rebase of last 3 commits
git rebase --continue                        # Continue after resolving conflicts
git rebase --abort                           # Cancel rebase operation
```
**When to use:** Cleaning up commit history or integrating changes without merge commits.

### Cherry Pick
```bash
git cherry-pick <commit-hash>                # Apply specific commit to current branch
git cherry-pick <commit1>..<commit2>         # Apply range of commits
```
**When to use:** Applying specific fixes or features from other branches.

### Advanced Branching
```bash
git branch -r                                # List remote branches
git branch -a                                # List all branches (local + remote)
git push --delete origin <branch>            # Delete remote branch
git branch -m <old-name> <new-name>          # Rename branch
```
**When to use:** Managing complex branching strategies or cleaning up old branches.

### Tags
```bash
git tag                                      # List all tags
git tag <tag-name>                           # Create lightweight tag
git tag -a <tag-name> -m "message"           # Create annotated tag with message
git push origin <tag-name>                   # Push specific tag to remote
git push origin --tags                       # Push all tags to remote
```
**When to use:** Marking release versions or important milestones.

### Advanced Operations
```bash
git reflog                                   # View reference log (recovery tool)
git bisect start                             # Start binary search for bugs
git bisect bad                               # Mark current commit as bad
git bisect good <commit>                     # Mark commit as good
git clean -n                                 # Preview files to be cleaned
git clean -f                                 # Remove untracked files
git blame <file>                             # Show who changed each line
```
**When to use:** Debugging, recovery operations, or detailed code analysis.

## Git Workflow Patterns

### Feature Branch Workflow
```bash
git checkout -b feature/new-feature          # Create feature branch
# Make changes
git add .                                    # Stage changes
git commit -m "Add new feature"              # Commit changes
git push -u origin feature/new-feature       # Push and set upstream
# Create pull request
git checkout main                            # Switch back to main
git pull origin main                         # Update main branch
git branch -d feature/new-feature            # Delete local feature branch
```
**When to use:** Standard team development workflow for new features.

### Gitflow Workflow
```bash
git flow init                                # Initialize gitflow in repository
git flow feature start <feature-name>       # Start new feature
git flow feature finish <feature-name>      # Finish feature development
git flow release start <version>            # Start release preparation
git flow release finish <version>           # Complete release
```
**When to use:** Structured release management with multiple environments.

## Useful Git Aliases
```bash
git config --global alias.st status         # Shortcut for status
git config --global alias.co checkout       # Shortcut for checkout
git config --global alias.br branch         # Shortcut for branch
git config --global alias.cm commit         # Shortcut for commit
git config --global alias.lg "log --oneline --graph --decorate"  # Pretty log
```
**When to use:** Speed up daily Git operations with shorter commands.