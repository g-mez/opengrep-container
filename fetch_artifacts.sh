#!/usr/bin/env bash
# fetch-artifacts.sh
# Fetch latest OpenGrep binary and rules repo for air-gapped Docker build.

set -euo pipefail

ARTIFACTS_DIR="artifacts"
OPENGREP_DIR="${ARTIFACTS_DIR}/opengrep"
RULES_DIR="${ARTIFACTS_DIR}/rules"

# Function to fetch available versions from GitHub
get_available_versions() {
    curl -s "https://api.github.com/repos/opengrep/opengrep/releases" \
      | grep -oP '"tag_name":\s*"\Kv[0-9]+\.[0-9]+\.[0-9]+' \
      | sed 's/^v//'
}

# Determine OpenGrep version to use
if [[ $# -eq 0 ]]; then
    # If no version provided, use the latest
    VERSION=$(get_available_versions | head -1)
else
    VERSION="$1"
    AVAILABLE_VERSIONS=$(get_available_versions)
    if echo "$AVAILABLE_VERSIONS" | grep -q "^$VERSION$"; then
        echo "[INFO] Using OpenGrep version $VERSION"
    else
        echo "[ERROR] Version $VERSION not found"
        echo "Available versions (latest 3):"
        echo "$AVAILABLE_VERSIONS" | head -3
        exit 1
    fi
fi

echo "[INFO] OpenGrep version to fetch: $VERSION"

# Download OpenGrep binary
BIN_DIR="${OPENGREP_DIR}/${VERSION}"
TARGET_BIN="${BIN_DIR}/opengrep"

if [[ -f "$TARGET_BIN" ]]; then
    echo "[OK] OpenGrep $VERSION binary already exists at $TARGET_BIN"
else
    echo "[INFO] Downloading OpenGrep $VERSION binary..."
    mkdir -p "$BIN_DIR"
    ASSET="opengrep_manylinux_x86"
    DOWNLOAD_URL="https://github.com/opengrep/opengrep/releases/download/v${VERSION}/${ASSET}"

    curl -fL -o "${BIN_DIR}/${ASSET}" "$DOWNLOAD_URL"
    mv "${BIN_DIR}/${ASSET}" "$TARGET_BIN"
    chmod +x "$TARGET_BIN"

    echo "[OK] OpenGrep binary ready at $TARGET_BIN"
fi

# Download OpenGrep rules
if [[ -d "$RULES_DIR" ]]; then
    echo "[OK] Rules already exist at $RULES_DIR"
else
    echo "[INFO] Downloading OpenGrep rules repo..."
    git clone --depth 1 https://github.com/opengrep/opengrep-rules.git "$RULES_DIR"
    echo "[OK] Rules downloaded to $RULES_DIR"

    # Cleanup rules directory to remove non-rule artifacts, including hidden files
    echo "[INFO] Cleaning up rules directory..."
    cd "$RULES_DIR"

    KEEP_DIRS=("ai" "apex" "bash" "c" "clojure" "csharp" "dockerfile" "elixir" "generic" "go" "html" "java" "javascript" "json" "kotlin" "libsonnet" "ocaml" "php" "problem-based-packs" "python" "ruby" "rust" "scala" "solidity" "swift" "terraform" "trusted_python" "typescript" "yaml")

    shopt -s dotglob nullglob
    for entry in *; do
        if [[ ! " ${KEEP_DIRS[*]} " =~ " ${entry} " ]]; then
            echo "[INFO] Removing $entry"
            rm -rf "$entry"
        fi
    done
    shopt -u dotglob nullglob

    cd - >/dev/null
fi

# Docker build command
echo
cat <<EOF
Artifacts prepared:
  Binary: ${TARGET_BIN}
  Rules:  ${RULES_DIR}

Docker build command to run (from project root):

  docker build -t opengrep-airgap:latest \
    --build-arg OPENGREP_VERSION=${VERSION} .

EOF
