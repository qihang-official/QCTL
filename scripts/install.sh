#!/usr/bin/env bash
set -euo pipefail

REPO="${QCTL_GITHUB_REPO:-qihang-official/QCTL}"
VERSION_INPUT="${1:-latest}"
INSTALL_HOME="${QCTL_HOME:-$HOME/.local/share/qctl}"
BIN_DIR="${QCTL_BIN_DIR:-$HOME/.local/bin}"
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
AUTO_RUN="${QCTL_AUTO_RUN:-1}"
RUN_CMD="${QCTL_RUN_CMD:-init}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

detect_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  if [[ "$os" != "linux" ]]; then
    echo "unsupported OS: $os (only linux is supported by current release artifacts)" >&2
    exit 1
  fi

  case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)
      echo "unsupported architecture: $arch" >&2
      exit 1
      ;;
  esac

  printf '%s %s\n' "$os" "$arch"
}

resolve_version() {
  local requested="$1"
  if [[ "$requested" != "latest" ]]; then
    printf '%s\n' "$requested"
    return
  fi

  local tag
  tag="$(
    api_curl "https://api.github.com/repos/${REPO}/releases/latest" \
      | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' \
      | head -n 1
  )"
  if [[ -z "$tag" ]]; then
    echo "failed to resolve latest release version from GitHub API" >&2
    exit 1
  fi
  printf '%s\n' "$tag"
}

api_curl() {
  local url="$1"
  if [[ -n "$TOKEN" ]]; then
    curl -fsSL \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      "$url"
  else
    curl -fsSL "$url"
  fi
}

download_with_api() {
  local version="$1"
  local asset_name="$2"
  local out_path="$3"
  local release_json asset_id

  release_json="$(api_curl "https://api.github.com/repos/${REPO}/releases/tags/${version}")"
  asset_id="$(
    printf '%s' "$release_json" \
      | sed -n "/\"name\": \"${asset_name}\"/,/\"state\":/ s/.*\"id\": \([0-9][0-9]*\).*/\1/p" \
      | head -n 1
  )"

  if [[ -z "$asset_id" ]]; then
    echo "failed to find asset '${asset_name}' in release ${version}" >&2
    exit 1
  fi

  if [[ -z "$TOKEN" ]]; then
    echo "GH_TOKEN or GITHUB_TOKEN is required to download private release assets" >&2
    exit 1
  fi

  curl -fL \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/octet-stream" \
    "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}" \
    -o "$out_path"
}

download_with_public_url() {
  local version="$1"
  local asset_name="$2"
  local out_path="$3"
  curl -fL "https://github.com/${REPO}/releases/download/${version}/${asset_name}" -o "$out_path"
}

verify_checksum() {
  local archive="$1"
  local sums_file="$2"
  local archive_name
  archive_name="$(basename "$archive")"

  if command -v sha256sum >/dev/null 2>&1; then
    (
      cd "$(dirname "$archive")"
      grep " ${archive_name}\$" "$sums_file" | sha256sum -c -
    )
    return
  fi

  if command -v shasum >/dev/null 2>&1; then
    local expected actual
    expected="$(grep " ${archive_name}\$" "$sums_file" | awk '{print $1}')"
    actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
    if [[ "$expected" != "$actual" ]]; then
      echo "checksum verification failed for ${archive_name}" >&2
      exit 1
    fi
    return
  fi

  echo "warning: sha256sum/shasum not found, skip checksum verification" >&2
}

main() {
  require_cmd curl
  require_cmd tar
  require_cmd ln
  require_cmd awk
  require_cmd sed

  read -r os arch <<<"$(detect_platform)"
  version="$(resolve_version "$VERSION_INPUT")"

  archive_name="qctl-${os}-${arch}.tar.gz"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  archive_path="${tmp_dir}/${archive_name}"
  sums_path="${tmp_dir}/sha256sums.txt"
  extracted_bin="${tmp_dir}/qctl-${os}-${arch}"

  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      echo "downloading assets via gh from ${REPO} ${version}"
      gh release download "$version" --repo "$REPO" --pattern "$archive_name" --pattern "sha256sums.txt" --dir "$tmp_dir"
    else
      echo "gh found but not authenticated, fallback to direct URL mode"
      if ! download_with_public_url "$version" "$archive_name" "$archive_path"; then
        if [[ -n "$TOKEN" ]]; then
          download_with_api "$version" "$archive_name" "$archive_path"
        else
          echo "failed to download ${archive_name}; if repo is private, set GH_TOKEN/GITHUB_TOKEN" >&2
          exit 1
        fi
      fi
      if ! download_with_public_url "$version" "sha256sums.txt" "$sums_path"; then
        if [[ -n "$TOKEN" ]]; then
          download_with_api "$version" "sha256sums.txt" "$sums_path"
        else
          echo "failed to download sha256sums.txt; if repo is private, set GH_TOKEN/GITHUB_TOKEN" >&2
          exit 1
        fi
      fi
    fi
  else
    if ! download_with_public_url "$version" "$archive_name" "$archive_path"; then
      if [[ -n "$TOKEN" ]]; then
        download_with_api "$version" "$archive_name" "$archive_path"
      else
        echo "failed to download ${archive_name}; if repo is private, set GH_TOKEN/GITHUB_TOKEN" >&2
        exit 1
      fi
    fi
    if ! download_with_public_url "$version" "sha256sums.txt" "$sums_path"; then
      if [[ -n "$TOKEN" ]]; then
        download_with_api "$version" "sha256sums.txt" "$sums_path"
      else
        echo "failed to download sha256sums.txt; if repo is private, set GH_TOKEN/GITHUB_TOKEN" >&2
        exit 1
      fi
    fi
  fi

  verify_checksum "$archive_path" "$sums_path"

  mkdir -p "$INSTALL_HOME/versions/$version" "$BIN_DIR"
  tar -xzf "$archive_path" -C "$tmp_dir"
  install_path="$INSTALL_HOME/versions/$version/qctl"
  mv "$extracted_bin" "$install_path"
  chmod +x "$install_path"

  ln -sfn "$install_path" "$BIN_DIR/qctl"

  echo "installed: $install_path"
  echo "linked: $BIN_DIR/qctl"
  if [[ "$AUTO_RUN" == "1" ]]; then
    if [[ -t 0 && -t 1 ]]; then
      echo "running: qctl ${RUN_CMD}"
      "$BIN_DIR/qctl" ${RUN_CMD}
    else
      echo "non-interactive shell detected, running: qctl version"
      "$BIN_DIR/qctl" version
    fi
  else
    "$BIN_DIR/qctl" version
  fi

  if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "hint: add this to your shell profile -> export PATH=\"$BIN_DIR:\$PATH\""
  fi
}

main "$@"
