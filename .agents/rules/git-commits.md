# Git Commits and Pushes

Before running any commands that modify the git history (e.g., `git commit`) or push to a remote repository (e.g., `git push`), you MUST consult the user and obtain their explicit permission first.

Do not assume you have permission to commit or push just because you have generated code or finished a task. Always ask the user if they are ready to commit the changes.

## Conventional Commits

When writing git commit messages, you MUST strictly adhere to the Conventional Commits convention:
- Use standard prefixes like `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, etc.
- The description immediately following the prefix MUST start with a capitalized word (e.g. Add, Update, Fix, Remove).

**Correct Examples:**
- `feat: Add login support via google`
- `fix: Resolve layout overflow on small screens`
- `chore: Update dependency versions`

**Incorrect Examples:**
- `feat: add login support via google` (lowercase 'add')
- `Added login support` (missing prefix)
