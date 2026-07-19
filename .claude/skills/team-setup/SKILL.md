---
name: team-setup
description: Inject this repo's skills into the user level (~/.claude/skills) so they work in every project on this machine. Run once per machine; after that, git pull alone keeps skills in sync. Also sets the TEAM_WORKFLOWS_DIR environment variable. Use on requests like "setup", "machine setup", or "team-setup".
---

# User-level setup for the team AI workflow repo

After this runs, every Claude Code session on this machine can use the skills under `skills/`, no matter which directory it starts in. New projects need no per-project setup.

## Path resolution

Resolve the repo root (`TEAM_WORKFLOWS_DIR`) with `git rev-parse --show-toplevel`. This skill must be run from a Claude Code session started **inside this repository**.

## Design constraints (do not change)

- Use **one link per skill**. Never create a single link over the whole `~/.claude/skills` folder or a grouping subfolder (`~/.claude/skills/<group>/<skill>/`). Nested layouts are not discovered when the session cwd is a git repository.

## Workflow

### Step 1. Sync skill links (always)

```bash
bash "<TEAM_WORKFLOWS_DIR>/.claude/skills/team-setup/scripts/sync_user_skills.sh"
```

This links every skill under `skills/` into `~/.claude/skills/<name>` (idempotent — safe to re-run any time):

- missing link -> created `[created]`
- broken link (skill deleted / repo moved) -> removed `[removed]` (recreated at the new path on the same run if the skill still exists)
- existing entry -> left untouched (counted as `kept`)

After syncing, list the entries (Windows: `cmd /c "dir %USERPROFILE%\.claude\skills /AL"` / macOS & Linux: `ls -la ~/.claude/skills`). If a skill name from `skills/` is missing from the link list, a **real folder with the same name already exists** (a personal skill conflict). Present the conflicting names and use AskUserQuestion to choose between: keep the personal skill (skip injection) / rename it to `<name>.personal-backup` and inject the team version.

### Step 2. Install the post-merge hook (always)

Makes `git pull` re-run Step 1 automatically, so new skills arrive with a plain pull:

1. Check whether `<TEAM_WORKFLOWS_DIR>/.git/hooks/post-merge` exists
2. If missing: copy `.claude/skills/team-setup/scripts/post-merge` there and `chmod +x` it
3. If present with different content: another hook may be installed — confirm the overwrite with AskUserQuestion

If the hook cannot be installed (permissions etc.), ask the user to run this one line manually:

```bash
cp .claude/skills/team-setup/scripts/post-merge .git/hooks/post-merge
```

### Step 3. Set the TEAM_WORKFLOWS_DIR environment variable (always)

Add to the `env` block of `~/.claude/settings.json` (always preserve every existing key when writing the file back):

```jsonc
{
  "env": {
    "TEAM_WORKFLOWS_DIR": "<absolute path of this repo>"
  }
}
```

Skill scripts (e.g. the knowledge search in `/docs-grep`) use this to locate `sources/`. The scripts also have a self-location fallback, but set the variable anyway for redundancy.

### Step 4. Verify and report

1. List the skill links again to confirm
2. Report: sync results (created / removed / kept), hook status, and the `env.TEAM_WORKFLOWS_DIR` value
3. Close with: "Restart your Claude Code session and the team skills will appear in every project. From now on, a plain `git pull` in this repo keeps them up to date."
