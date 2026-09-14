#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# auto-submodules.sh (v3)
#
# Finds ALL nested Git repositories underneath the current
# directory — including repos nested inside other repos — and
# adds them as Git submodules using their existing "origin".
#
# When a repo has no "origin" remote (common for Meson
# subprojects fetched via .wrap files), this version falls
# back to:
#   1. any other configured remote, then
#   2. the "url =" line in the matching subprojects/<name>.wrap
#
# Usage:
#   ./auto-submodules.sh          # dry run
#   ./auto-submodules.sh --apply  # actually add submodules
# ------------------------------------------------------------

ROOT="$(pwd -P)"
APPLY=false

if [[ "${1:-}" == "--apply" ]]; then
    APPLY=true
fi

echo "Root: $ROOT"
echo

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
    echo "ERROR: Current directory is not a Git repository."
    exit 1
fi

GIT_ROOT="$(git rev-parse --show-toplevel)"
GIT_ROOT="$(cd "$GIT_ROOT" && pwd -P)"

if [[ "$GIT_ROOT" != "$ROOT" ]]; then
    echo "ERROR: Run this script from the root of the superproject."
    echo "Git root: $GIT_ROOT"
    echo "Current : $ROOT"
    exit 1
fi

declare -a FOUND=()
declare -a SKIPPED=()
declare -a FAILED=()
declare -a NO_URL_AT_ALL=()   # truly nothing found — not even a .wrap

# Directories we never want to descend into (huge, irrelevant, or dangerous)
PRUNE_NAMES=(node_modules vendor .venv venv __pycache__ dist build .cache)

echo "Searching for Git repositories (including nested-in-nested)..."
echo

# Build an existing-submodule-path lookup once, up front, from GIT_ROOT.
declare -A SUBMODULE_PATHS=()
if [[ -f "$GIT_ROOT/.gitmodules" ]]; then
    while IFS= read -r p; do
        [[ -n "$p" ]] && SUBMODULE_PATHS["$p"]=1
    done < <(git config --file "$GIT_ROOT/.gitmodules" --get-regexp '^submodule\..*\.path$' 2>/dev/null | awk '{print $2}')
fi

# --------------------------------------------------------------
# Tier 3 fallback: a curated map of canonical upstream URLs for
# well-known C libraries commonly vendored by hand (no .wrap,
# no remote) into graphics/display source trees. Keyed by the
# directory's basename. Verified against upstream docs/mirrors
# as of Sep 2026 — double-check before trusting blindly, since
# a same-named directory could in principle be something else.
# --------------------------------------------------------------
declare -A KNOWN_URLS=(
    [cairo]="https://gitlab.freedesktop.org/cairo/cairo.git"
    [fontconfig]="https://gitlab.freedesktop.org/fontconfig/fontconfig.git"
    [freetype]="https://gitlab.freedesktop.org/freetype/freetype.git"
    [dlg]="https://github.com/nyorain/dlg.git"
    [fribidi]="https://github.com/fribidi/fribidi.git"
    [harfbuzz]="https://github.com/harfbuzz/harfbuzz.git"
    [pango]="https://gitlab.gnome.org/GNOME/pango.git"
    [pixman]="https://gitlab.freedesktop.org/pixman/pixman.git"
    [at-spi2-core]="https://gitlab.gnome.org/GNOME/at-spi2-core.git"
    [gdk-pixbuf]="https://gitlab.gnome.org/GNOME/gdk-pixbuf.git"
    [glib]="https://gitlab.gnome.org/GNOME/glib.git"
    [gobject-introspection]="https://gitlab.gnome.org/GNOME/gobject-introspection.git"
    [gobject-introspection-tests]="https://gitlab.gnome.org/GNOME/gobject-introspection-tests.git"
    [expat]="https://github.com/libexpat/libexpat.git"
    [libffi]="https://github.com/libffi/libffi.git"
    [libjpeg-turbo]="https://github.com/libjpeg-turbo/libjpeg-turbo.git"
    [libpng]="https://github.com/pnggroup/libpng.git"
    [libtiff]="https://gitlab.com/libtiff/libtiff.git"
    [libxml2]="https://gitlab.gnome.org/GNOME/libxml2.git"
    [pcre2]="https://github.com/PCRE2Project/pcre2.git"
    [sljit]="https://github.com/zherczeg/sljit.git"
    [zlib]="https://github.com/madler/zlib.git"
    [gtk3]="https://gitlab.gnome.org/GNOME/gtk.git"
    [libdrm]="https://gitlab.freedesktop.org/mesa/drm.git"
    [libepoxy]="https://github.com/anholt/libepoxy.git"
    [mesa]="https://gitlab.freedesktop.org/mesa/mesa.git"
    [wayland-protocols]="https://gitlab.freedesktop.org/wayland/wayland-protocols.git"
    [wayland]="https://gitlab.freedesktop.org/wayland/wayland.git"
    [libxkbcommon]="https://github.com/xkbcommon/libxkbcommon.git"
    [xkeyboard-config]="https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config.git"
)

# Directories in the known map that need special handling after
# `git submodule add` — either a non-default branch, or the URL
# points at a monorepo rather than a 1:1 mirror of this subfolder.
declare -A KNOWN_CAVEATS=(
    [gtk3]="Default branch is now GTK4 'main'. After adding, run: git -C Graphics/GTK3/Graphics/gtk3 checkout gtk-3-24 (or whatever ref your tree was pinned to)."
    [expat]="Upstream is the libexpat monorepo (contains an inner 'expat/' subdir), NOT a 1:1 mirror of just the C library. The submodule will include extra siblings (expat/tests, etc.) — review before committing."
    [gobject-introspection-tests]="Lower confidence — verify this repo/URL actually exists and matches what's vendored before applying."
)

# --------------------------------------------------------------
# Try to recover a git URL for a repo that has no "origin" remote.
#   1. Any other configured remote (first one wins).
#   2. A sibling subprojects/<name>.wrap file's [wrap-git] url.
#   3. The curated KNOWN_URLS map, keyed by directory basename.
# Prints "URL|SOURCE_TAG" on stdout, or nothing if it can't find one.
# --------------------------------------------------------------
resolve_fallback_url() {
    local repo="$1"

    # 1. Any other remote at all
    local other url
    other="$(git -C "$repo" remote 2>/dev/null | head -n1 || true)"
    if [[ -n "$other" ]]; then
        url="$(git -C "$repo" remote get-url "$other" 2>/dev/null || true)"
        if [[ -n "$url" ]]; then
            echo "${url}|remote:${other}"
            return 0
        fi
    fi

    # 2. Meson .wrap fallback: only applies if the repo's parent dir
    #    is literally named "subprojects" (the meson convention).
    local dir name parent wrapfile wrapurl
    dir="$(dirname "$repo")"
    name="$(basename "$repo")"
    parent="$(basename "$dir")"

    if [[ "$parent" == "subprojects" ]]; then
        wrapfile="$dir/$name.wrap"
        if [[ -f "$wrapfile" ]]; then
            wrapurl="$(awk '
                /^\[wrap-git\]/ { in_git=1; next }
                /^\[/ { in_git=0 }
                in_git && /^url[ \t]*=/ {
                    sub(/^url[ \t]*=[ \t]*/, "");
                    print;
                    exit
                }
            ' "$wrapfile")"
            if [[ -n "$wrapurl" ]]; then
                echo "${wrapurl}|wrap-file"
                return 0
            fi
        fi
    fi

    # 3. Curated known-project map, by directory basename.
    if [[ -n "${KNOWN_URLS[$name]:-}" ]]; then
        echo "${KNOWN_URLS[$name]}|known-project"
        return 0
    fi
}

# Recursive scan. Unlike `find -prune`, this explicitly recurses INTO
# every directory we find, including ones that are themselves git repos,
# so repos-within-repos are still discovered.
scan_dir() {
    local dir="$1"
    local entry base

    for entry in "$dir"/* "$dir"/.[!.]* "$dir"/..?*; do
        [[ -e "$entry" ]] || continue          # handle no-match globs
        [[ -L "$entry" ]] && continue          # skip symlinks (avoid loops)
        [[ -d "$entry" ]] || continue

        base="$(basename "$entry")"

        for skip in "${PRUNE_NAMES[@]}"; do
            [[ "$base" == "$skip" ]] && continue 2
        done

        if [[ -e "$entry/.git" ]]; then
            process_repo "$entry"
        fi

        scan_dir "$entry"
    done
}

process_repo() {
    local repo="$1"
    repo="$(cd "$repo" && pwd -P)"

    [[ "$repo" == "$ROOT" ]] && return

    local rel="${repo#$ROOT/}"

    if [[ -n "${SUBMODULE_PATHS[$rel]:-}" ]]; then
        echo "[SKIP] Already a submodule: $rel"
        SKIPPED+=("$rel")
        return
    fi

    local url="" source="origin" fallback=""

    if git -C "$repo" remote get-url origin >/dev/null 2>&1; then
        url="$(git -C "$repo" remote get-url origin)"
    else
        fallback="$(resolve_fallback_url "$repo" || true)"
        if [[ -n "$fallback" ]]; then
            url="${fallback%|*}"
            source="${fallback##*|}"
        fi
    fi

    if [[ -z "$url" ]]; then
        echo "[SKIP] No origin, no other remote, no .wrap, not in known-project map: $rel"
        SKIPPED+=("$rel")
        NO_URL_AT_ALL+=("$rel")
        return
    fi

    local basename_only
    basename_only="$(basename "$repo")"
    if [[ "$source" == "known-project" && -n "${KNOWN_CAVEATS[$basename_only]:-}" ]]; then
        echo "  ! NOTE: ${KNOWN_CAVEATS[$basename_only]}"
    fi

    local commit
    commit="$(git -C "$repo" rev-parse HEAD 2>/dev/null || echo "unknown")"

    FOUND+=("$rel")

    echo "[FOUND]"
    echo "  Path   : $rel"
    echo "  Origin : $url  (via $source)"
    echo "  Commit : $commit"
    echo

    if [[ "$APPLY" == true ]]; then
        if git -C "$GIT_ROOT" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
            echo "[SKIP] Path is already tracked: $rel"
            SKIPPED+=("$rel")
            echo
            return
        fi

        # Clean up a stale .git/modules/<rel> left behind by a previous
        # add attempt that died mid-clone (e.g. a network 502). If this
        # exists but the path isn't a registered submodule, it's corrupt
        # leftover state that will make git try to "reactivate" a broken
        # gitdir instead of cloning fresh.
        local moddir="$GIT_ROOT/.git/modules/$rel"
        if [[ -e "$moddir" ]]; then
            echo "[CLEANUP] Removing stale submodule gitdir from a previous failed attempt: .git/modules/$rel"
            rm -rf "$moddir"
        fi

        # If the existing .git has no commits (orphaned/empty init — common
        # for tarball-extracted vendor trees that were `git init`'d but
        # never committed), `git submodule add` cannot adopt it in place:
        # it errors "already exists and is not a valid git repo". Move it
        # aside first so submodule add does a clean clone instead.
        local backup=""
        if [[ "$commit" == "unknown" ]]; then
            backup="${repo}.orphan-backup-$(date +%Y%m%d%H%M%S)"
            echo "[BACKUP] No commits in existing .git — moving aside to: ${backup#$ROOT/}"
            mv "$repo" "$backup"
        fi

        echo "[ADD] $url -> $rel"

        # -f: some vendored subproject dirs are matched by a parent
        # .gitignore rule (e.g. meson's common "subprojects/*" pattern);
        # without -f, submodule add refuses ignored paths outright.
        if git -C "$GIT_ROOT" submodule add -f "$url" "$rel" < /dev/null; then
            echo "[OK] Added: $rel"
            if [[ -n "$backup" ]]; then
                echo "     (orphaned original preserved at: ${backup#$ROOT/} — diff/delete once verified)"
            fi
        else
            echo "[FAILED] Could not add: $rel"
            FAILED+=("$rel")
            if [[ -n "$backup" ]]; then
                echo "     Restoring original directory from backup..."
                rm -rf "$repo" 2>/dev/null || true
                mv "$backup" "$repo"
            fi
        fi
        echo
    fi
}

scan_dir "$ROOT"

echo
echo "============================================================"
echo "SUMMARY"
echo "============================================================"

echo "Found            : ${#FOUND[@]}"
echo "Skipped          : ${#SKIPPED[@]}"
echo "  - of which truly unresolvable (no remote, no .wrap): ${#NO_URL_AT_ALL[@]}"
echo "Failed           : ${#FAILED[@]}"

if [[ "$APPLY" == false ]]; then
    echo
    echo "DRY RUN ONLY."
    echo
    echo "Nothing was modified."
    echo
    echo "If everything looks correct, run:"
    echo
    echo "    $0 --apply"
else
    echo
    echo "Submodule operation completed."
    echo
    echo "Don't forget to commit:"
    echo
    echo "    git add .gitmodules"
    echo "    git commit -m \"Add repositories as submodules\""
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo
    echo "Failed repositories:"
    printf '  %s\n' "${FAILED[@]}"
fi

if [[ ${#NO_URL_AT_ALL[@]} -gt 0 ]]; then
    echo
    echo "Truly unresolvable (check manually):"
    printf '  %s\n' "${NO_URL_AT_ALL[@]}"
fi
