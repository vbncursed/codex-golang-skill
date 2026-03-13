#!/usr/bin/env bash
set -euo pipefail

ROOT="."
MODE="quick"
CHANGED_ONLY="false"
LIST_ONLY="false"
DRY_RUN="false"

usage() {
  cat <<'EOF'
Usage: go_workspace_check.sh [options]

Options:
  --root <path>      Repository root to inspect (default: .)
  --mode <quick|full>
                     quick: gofmt/go test/go vet
                     full:  quick + go test -race + staticcheck (if present)
  --changed-only     Validate only modules affected by git-tracked file changes
  --list-modules     Print modules and exit
  --dry-run          Print commands without executing
  --help             Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      ROOT="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --changed-only)
      CHANGED_ONLY="true"
      shift
      ;;
    --list-modules)
      LIST_ONLY="true"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "$MODE" != "quick" && "$MODE" != "full" ]]; then
  echo "--mode must be quick or full" >&2
  exit 1
fi

ROOT="$(cd "$ROOT" && pwd)"

all_modules() {
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    (
      cd "$ROOT"
      git ls-files -- 'go.mod' '*/go.mod' | sed '/^$/d' | while IFS= read -r modfile; do
        dirname "$ROOT/$modfile"
      done
    ) | sort -u
    return
  fi

  find "$ROOT" -type f -name go.mod \
    -not -path '*/vendor/*' \
    -not -path '*/.cache/*' \
    -not -path '*/node_modules/*' \
    -exec dirname {} \; | sort -u
}

changed_modules() {
  if ! git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    all_modules
    return
  fi

  local changed_file
  changed_file="$(mktemp)"
  {
    git -C "$ROOT" diff --name-only
    git -C "$ROOT" diff --name-only --cached
    git -C "$ROOT" ls-files --others --exclude-standard
  } | sed '/^$/d' | sort -u >"$changed_file"

  if [[ ! -s "$changed_file" ]]; then
    rm -f "$changed_file"
    all_modules
    return
  fi

  while IFS= read -r rel; do
    abs="$ROOT/$rel"
    dir="$abs"
    [[ -f "$abs" ]] && dir="$(dirname "$abs")"
    while [[ "$dir" != "/" && "$dir" == "$ROOT"* ]]; do
      if [[ -f "$dir/go.mod" ]]; then
        echo "$dir"
        break
      fi
      dir="$(dirname "$dir")"
    done
  done <"$changed_file" | sort -u
  rm -f "$changed_file"
}

run_cmd() {
  local cmd="$1"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] $cmd"
    return 0
  fi
  eval "$cmd"
}

modules=()
if [[ "$CHANGED_ONLY" == "true" ]]; then
  while IFS= read -r module; do
    [[ -n "$module" ]] && modules+=("$module")
  done < <(changed_modules)
else
  while IFS= read -r module; do
    [[ -n "$module" ]] && modules+=("$module")
  done < <(all_modules)
fi

if [[ ${#modules[@]} -eq 0 ]]; then
  echo "No changed modules detected; falling back to all modules."
  while IFS= read -r module; do
    [[ -n "$module" ]] && modules+=("$module")
  done < <(all_modules)
fi

if [[ "$LIST_ONLY" == "true" ]]; then
  printf '%s\n' "${modules[@]}"
  exit 0
fi

echo "Mode: $MODE"
echo "Modules: ${#modules[@]}"

for module in "${modules[@]}"; do
  echo
  echo "==> $module"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] find . -type f -name '*.go' -not -path './vendor/*' -exec gofmt -w {} +"
  else
    (
      cd "$module"
      find . -type f -name '*.go' -not -path './vendor/*' -exec gofmt -w {} +
    )
  fi
  run_cmd "cd \"$module\" && go test ./..."
  run_cmd "cd \"$module\" && go vet ./..."

  if [[ "$MODE" == "full" ]]; then
    run_cmd "cd \"$module\" && go test -race ./..."
    if command -v staticcheck >/dev/null 2>&1; then
      run_cmd "cd \"$module\" && staticcheck ./..."
    else
      echo "  [skip] staticcheck not installed"
    fi
  fi
done

echo
echo "Workspace checks finished successfully."
