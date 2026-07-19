#!/bin/sh
# Sync user-level skill links for the team workflow repo.
#
# Creates one link per skill:
#   ~/.claude/skills/<name>  ->  <repo>/skills/<name>
#
# Idempotent: safe to run any number of times.
#   - missing link   -> created
#   - broken link    -> removed (and recreated if the skill still exists)
#   - existing entry -> left untouched (a real folder with a skill name is a
#                       conflict - resolved interactively by the setup skill)
#
# NOTE: do NOT replace this with a single link over the whole skills folder.
# Nested skill dirs (~/.claude/skills/<dir>/<skill>/SKILL.md) may not be
# discovered depending on the session cwd.

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$SCRIPT_DIR/../../../.." && pwd)
SRC="$REPO/skills"
DST="$HOME/.claude/skills"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) WIN=1 ;;
    *) WIN=0 ;;
esac

if [ ! -d "$SRC" ]; then
    echo "[error] source not found: $SRC"
    exit 1
fi
mkdir -p "$DST"

created=0; removed=0; kept=0

# 1) Remove broken links (entry listed but target unreachable).
for name in $(ls -A "$DST"); do
    entry="$DST/$name"
    if [ ! -e "$entry" ]; then
        if [ "$WIN" = 1 ]; then
            win_entry=$(cygpath -w "$entry")
            MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" cmd /c rmdir "$win_entry" > /dev/null 2>&1 \
                && { echo "[removed]  $name (broken link)"; removed=$((removed + 1)); }
        else
            [ -L "$entry" ] && rm "$entry" \
                && { echo "[removed]  $name (broken link)"; removed=$((removed + 1)); }
        fi
    fi
done

# 2) Create a link for every skill folder that has no entry yet.
for d in "$SRC"/*/; do
    name=$(basename "$d")
    entry="$DST/$name"
    if [ -e "$entry" ]; then
        kept=$((kept + 1))
    elif [ "$WIN" = 1 ]; then
        win_entry=$(cygpath -w "$entry")
        win_target=$(cygpath -w "${d%/}")
        MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" cmd /c mklink /J "$win_entry" "$win_target" > /dev/null 2>&1 \
            && { echo "[created]  $name"; created=$((created + 1)); } \
            || echo "[error]    $name (mklink failed)"
    else
        ln -s "${d%/}" "$entry" \
            && { echo "[created]  $name"; created=$((created + 1)); } \
            || echo "[error]    $name (symlink failed)"
    fi
done

echo "sync done: created=$created removed=$removed kept=$kept"
exit 0
