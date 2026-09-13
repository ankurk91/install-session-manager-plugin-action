#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Keep this in sync with the `path:` of the cache step in action.yaml.
CACHE_ROOT="$HOME/.cache/aws-ssm"
# Scoped per version so a persistent HOME on a self-hosted runner cannot serve
# the installer for a different version than the one that was asked for.
CACHE_PATH="$CACHE_ROOT/$VERSION"

echo "::debug::CACHE_ENABLED=$CACHE_ENABLED"
echo "::debug::CACHE_HIT=$CACHE_HIT"
echo "::debug::CACHE_PATH=$CACHE_PATH"
echo "::debug::OS=$OS"
echo "::debug::ARCH=$ARCH"
echo "::debug::VERSION=$VERSION"
echo "::debug::URL_SEGMENT=$URL_SEGMENT"

# Drop installers for other versions so the saved cache holds exactly one.
if [ -d "$CACHE_ROOT" ]; then
  find "$CACHE_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name "$VERSION" -exec rm -rf {} +
fi

mkdir -p "$CACHE_PATH"
cd "$CACHE_PATH"

REMOTE_URL_BASE="https://s3.amazonaws.com/session-manager-downloads/plugin"

if [ "$OS" = "ubuntu" ]; then
  INSTALLER="session-manager-plugin.deb"
  URL="${REMOTE_URL_BASE}/${URL_SEGMENT}/ubuntu_${ARCH}/${INSTALLER}"
else
  INSTALLER="session-manager-plugin.rpm"
  URL="${REMOTE_URL_BASE}/${URL_SEGMENT}/linux_${ARCH}/${INSTALLER}"
fi

download_plugin() {
  echo "Downloading $OS/$ARCH version $VERSION..."

  # S3 answers 403 rather than 404 for a missing key, so a typo in the version
  # looks like a permissions error. Say what was actually requested.
  if ! curl -sfL \
    --retry 3 \
    --retry-delay 5 \
    --connect-timeout 15 \
    --max-time 60 \
    -O "$URL"; then
    echo "::error::Failed to download $URL"
    echo "::error::If you pinned a version, check that $VERSION exists upstream."
    exit 1
  fi
}

# Amazon Linux 2, RHEL 7 and CentOS 7 ship yum without dnf, so pick whichever
# is present rather than assuming the newer one.
detect_package_manager() {
  if [ "$OS" = "ubuntu" ]; then
    echo "apt-get"
    return
  fi

  local pm
  for pm in dnf yum; do
    if command -v "$pm" >/dev/null 2>&1; then
      echo "$pm"
      return
    fi
  done

  echo "Error: Neither dnf nor yum was found on this runner" >&2
  exit 1
}

install_plugin() {
  echo "Installing plugin with $PACKAGE_MANAGER..."
  if [ "$PACKAGE_MANAGER" = "apt-get" ]; then
    sudo apt-get install -qq -y --no-install-recommends "./${INSTALLER}"
  else
    # dnf and yum agree on these flags, and both treat an argument containing a
    # slash as a local file rather than a repository package name.
    sudo "$PACKAGE_MANAGER" install -y -q "./${INSTALLER}"
  fi
}

# Resolved before downloading so that an unusable runner fails fast.
PACKAGE_MANAGER=$(detect_package_manager)
echo "::debug::PACKAGE_MANAGER=$PACKAGE_MANAGER"

if [ "$CACHE_ENABLED" != "true" ]; then
  # Caching is off, so never reuse a leftover file from a previous run on a
  # self-hosted runner with a persistent HOME.
  rm -f "$INSTALLER"
  download_plugin
elif [ ! -f "$INSTALLER" ]; then
  # Trust the file, not the cache-hit flag: a restored cache can be stale or
  # hold the installer for a different distro family.
  if [ "$CACHE_HIT" = "true" ]; then
    echo "::warning::Cache hit but ${INSTALLER} is missing, downloading it again."
  fi
  download_plugin
fi

install_plugin

session-manager-plugin --version
