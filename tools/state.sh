#!/usr/bin/env bash

STATE_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_REPO_ROOT="$(cd "$STATE_TOOLS_DIR/.." && pwd)"
DEVKIT_STATE_DIR="$STATE_REPO_ROOT/.super-dev-kit"
DEVKIT_MANIFEST="$DEVKIT_STATE_DIR/manifest.json"
DEVKIT_LOG_DIR="$DEVKIT_STATE_DIR/logs"
DEVKIT_EVENT_LOG="$DEVKIT_LOG_DIR/events.jsonl"

state_available() {
  command -v jq >/dev/null 2>&1
}

ensure_state() {
  if ! state_available; then
    return 1
  fi

  mkdir -p "$DEVKIT_STATE_DIR" "$DEVKIT_LOG_DIR"

  if [[ ! -f "$DEVKIT_MANIFEST" ]]; then
    jq -n       --arg platform "linux"       --arg host "$(hostname)"       --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)"       '{
        schema_version: 2,
        platform: $platform,
        host: $host,
        created_at: $now,
        updated_at: $now,
        profiles: [],
        stacks: [],
        modules: [],
        runtime_versions: {},
        packages: [],
        vscode_extensions: [],
        features: []
      }' > "$DEVKIT_MANIFEST"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"

  if jq     '.schema_version = 2
     | .profiles = (.profiles // [])
     | .stacks = (.stacks // [])
     | .modules = (.modules // [])
     | .runtime_versions = (.runtime_versions // {})
     | .packages = (.packages // [])
     | .vscode_extensions = (.vscode_extensions // [])
     | .features = (.features // [])'     "$DEVKIT_MANIFEST" > "$tmp"; then
    mv "$tmp" "$DEVKIT_MANIFEST"
  else
    rm -f "$tmp"
    return 1
  fi
}

state_write_filter() {
  local filter="$1"
  shift

  ensure_state || return 0

  local tmp
  tmp="$(mktemp)"

  if jq "$@" "$filter" "$DEVKIT_MANIFEST" > "$tmp"; then
    mv "$tmp" "$DEVKIT_MANIFEST"
  else
    rm -f "$tmp"
    return 1
  fi
}

state_add_profile() {
  local profile="$1"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  state_write_filter     '.profiles = ((.profiles + [$profile]) | unique) | .updated_at = $now'     --arg profile "$profile"     --arg now "$now"
}

state_add_stack() {
  local stack="$1"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  state_write_filter     '.stacks = ((.stacks + [$stack]) | unique) | .updated_at = $now'     --arg stack "$stack"     --arg now "$now"
}

state_add_module() {
  local module="$1"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  state_write_filter     '.modules = ((.modules + [$module]) | unique) | .updated_at = $now'     --arg module "$module"     --arg now "$now"
}

state_register_runtime_version() {
  local runtime="$1"
  local desired="$2"
  local actual="$3"
  local policy="${4:-informational}"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  state_write_filter     '.runtime_versions[$runtime] = {
        desired: $desired,
        actual: $actual,
        policy: $policy,
        last_seen_at: $now
      }
      | .updated_at = $now'     --arg runtime "$runtime"     --arg desired "$desired"     --arg actual "$actual"     --arg policy "$policy"     --arg now "$now"
}

state_register_package() {
  local id="$1"
  local name="$2"
  local manager="$3"
  local preexisting="$4"
  local present_after="$5"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  state_write_filter     '
      (.packages // []) as $items
      | ($items | map(select(.id == $id and .manager == $manager)) | first) as $existing
      | (($preexisting | not) and $present_after) as $new_owned
      | (($existing.installed_by_devkit // false) or $new_owned) as $owned
      | .packages = (
          $items
          | map(select((.id == $id and .manager == $manager) | not))
          + [{
              id: $id,
              name: $name,
              manager: $manager,
              preexisting: $preexisting,
              installed_by_devkit: $owned,
              present: $present_after,
              last_seen_at: $now
            }]
        )
      | .updated_at = $now
    '     --arg id "$id"     --arg name "$name"     --arg manager "$manager"     --argjson preexisting "$preexisting"     --argjson present_after "$present_after"     --arg now "$now"
}

state_register_extension() {
  local id="$1"
  local preexisting="$2"
  local present_after="$3"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  state_write_filter     '
      (.vscode_extensions // []) as $items
      | ($items | map(select(.id == $id)) | first) as $existing
      | (($preexisting | not) and $present_after) as $new_owned
      | (($existing.installed_by_devkit // false) or $new_owned) as $owned
      | .vscode_extensions = (
          $items
          | map(select(.id != $id))
          + [{
              id: $id,
              preexisting: $preexisting,
              installed_by_devkit: $owned,
              present: $present_after,
              last_seen_at: $now
            }]
        )
      | .updated_at = $now
    '     --arg id "$id"     --argjson preexisting "$preexisting"     --argjson present_after "$present_after"     --arg now "$now"
}

state_register_feature() {
  local name="$1"
  local preexisting="$2"
  local present_after="$3"
  local now
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  state_write_filter     '
      (.features // []) as $items
      | ($items | map(select(.name == $name)) | first) as $existing
      | (($preexisting | not) and $present_after) as $new_owned
      | (($existing.enabled_by_devkit // false) or $new_owned) as $owned
      | .features = (
          $items
          | map(select(.name != $name))
          + [{
              name: $name,
              preexisting: $preexisting,
              enabled_by_devkit: $owned,
              present: $present_after,
              last_seen_at: $now
            }]
        )
      | .updated_at = $now
    '     --arg name "$name"     --argjson preexisting "$preexisting"     --argjson present_after "$present_after"     --arg now "$now"
}

log_event() {
  local level="$1"
  local event="$2"
  local message="${3:-}"

  ensure_state || return 0

  jq -nc     --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)"     --arg level "$level"     --arg event "$event"     --arg message "$message"     '{timestamp:$timestamp,level:$level,event:$event,data:{message:$message}}'     >> "$DEVKIT_EVENT_LOG"
}
