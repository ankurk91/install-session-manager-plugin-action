#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

if command -v session-manager-plugin >/dev/null 2>&1; then
    echo "AWS session-manager-plugin is already installed. Skipping install."
    session-manager-plugin --version
    echo "AWS_SESSION_MANAGER_PREINSTALLED=true" >> "$GITHUB_OUTPUT"
    exit 0
fi

echo "AWS_SESSION_MANAGER_PREINSTALLED=false" >> "$GITHUB_OUTPUT"

# Detect the platform and resolve the version here rather than in install.sh,
# because the cache key needs both before the cache step runs.

REMOTE_URL_BASE="https://s3.amazonaws.com/session-manager-downloads/plugin"

detect_arch() {
    case $(uname -m) in
        x86_64|amd64)
            echo "64bit"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "Error: Unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

detect_os() {
  if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    case "$ID" in
      amzn|rhel|centos|fedora)
      echo "amazon"
      ;;
      ubuntu|debian)
       echo "ubuntu"
       ;;
      *)
        echo "Error: Unsupported OS: $ID" >&2;
        exit 1
        ;;
    esac
  else
    echo "Error: Could not detect OS" >&2
    exit 1
  fi
}

is_version_number() {
  [[ "$1" =~ ^[0-9]+(\.[0-9]+)+$ ]]
}

# Sets VERSION (the cache token) and URL_SEGMENT (the path to download from).
#
# These are set as globals rather than echoed, because IFS is deliberately
# narrowed to newline and tab above, so `read` would not split them on a space.
#
# The two differ only when resolving `latest` fails: the download still has to
# work, so the URL falls back to `latest`, while the cache token falls back to
# an ISO week so a cache populated today expires within 7 days instead of
# pinning the repo to this version forever.
VERSION=""
URL_SEGMENT=""

resolve_version() {
  if [ "$INPUT_VERSION" != "latest" ]; then
    if ! is_version_number "$INPUT_VERSION"; then
      echo "Error: Invalid version '$INPUT_VERSION', expected e.g. 1.2.835.0 or 'latest'" >&2
      exit 1
    fi
    VERSION="$INPUT_VERSION"
    URL_SEGMENT="$INPUT_VERSION"
    return
  fi

  local marker
  marker=$(curl -sfL --retry 2 --connect-timeout 5 --max-time 10 \
    "${REMOTE_URL_BASE}/latest/VERSION" 2>/dev/null | tr -d '[:space:]' || true)

  # Guard against a truncated response or an error page becoming a cache key.
  if is_version_number "$marker"; then
    VERSION="$marker"
    URL_SEGMENT="$marker"
  else
    echo "::warning::Could not resolve the latest version, the cache will expire weekly instead."
    VERSION="latest-$(date -u +%G-W%V)"
    URL_SEGMENT="latest"
  fi
}

# Assign first so that a failure aborts the step; a failing command
# substitution inside `echo` would not.
OS=$(detect_os)
ARCH=$(detect_arch)
resolve_version

echo "Resolved $OS/$ARCH version '$INPUT_VERSION' to '$VERSION' (downloading from '$URL_SEGMENT')"

{
  echo "AWS_SESSION_MANAGER_OS=$OS"
  echo "AWS_SESSION_MANAGER_ARCH=$ARCH"
  echo "AWS_SESSION_MANAGER_VERSION=$VERSION"
  echo "AWS_SESSION_MANAGER_URL_SEGMENT=$URL_SEGMENT"
} >> "$GITHUB_OUTPUT"
