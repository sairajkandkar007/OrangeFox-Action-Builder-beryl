#!/usr/bin/env bash
# Temporary TWRP compatibility layer for Beryl device tree.
# Does NOT permanently modify the GitHub device tree.
#
# Usage:
#   ./scripts/twrp-compat.sh apply  device/xiaomi/beryl
#   ./scripts/twrp-compat.sh restore device/xiaomi/beryl
#
set -euo pipefail

CMD="${1:-}"
TREE="${2:-}"

if [[ -z "$CMD" || -z "$TREE" ]]; then
  echo "Usage: $0 apply|restore <device-tree-path>"
  exit 1
fi

if [[ ! -d "$TREE" ]]; then
  echo "ERROR: device tree path not found: $TREE"
  exit 1
fi

STATE_DIR="${TREE}/.compat-state"
BACKUP_DIR="${STATE_DIR}/backup"

apply_compat() {
  if [[ -f "${STATE_DIR}/active" ]]; then
    echo "TWRP compat already active — skipping apply"
    return 0
  fi

  mkdir -p "$BACKUP_DIR"

  if [[ -f "${TREE}/AndroidProducts.mk" ]]; then
    cp -a "${TREE}/AndroidProducts.mk" "${BACKUP_DIR}/AndroidProducts.mk"

    cat > "${TREE}/AndroidProducts.mk" << 'APMK'
#
# Temporary TWRP-only product selection (workspace overlay)
# Restored by scripts/twrp-compat.sh restore
#
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_beryl.mk

COMMON_LUNCH_CHOICES := \
    twrp_beryl-bp2a-eng \
    twrp_beryl-eng
APMK
    echo "Applied: AndroidProducts.mk → TWRP-only products"
  else
    echo "ERROR: AndroidProducts.mk missing in $TREE"
    exit 1
  fi

  if [[ ! -f "${TREE}/twrp_beryl.mk" ]]; then
    echo "ERROR: twrp_beryl.mk not found — TWRP product missing"
    exit 1
  fi

  if grep -qE '^\s*OF_' "${TREE}/twrp_beryl.mk"; then
    echo "WARNING: twrp_beryl.mk contains OF_* vars (OrangeFox-specific)"
    echo "         Consider cleaning them for pure TWRP builds"
  fi

  if [[ -f "${TREE}/fox_beryl.mk" ]]; then
    echo "Note: fox_beryl.mk present but excluded from PRODUCT_MAKEFILES"
  fi

  date -u +%Y-%m-%dT%H:%M:%SZ > "${STATE_DIR}/active"
  echo "TWRP compat layer ACTIVE on $TREE"
}

restore_compat() {
  if [[ ! -f "${STATE_DIR}/active" ]]; then
    echo "TWRP compat not active — nothing to restore"
    return 0
  fi

  if [[ -f "${BACKUP_DIR}/AndroidProducts.mk" ]]; then
    cp -a "${BACKUP_DIR}/AndroidProducts.mk" "${TREE}/AndroidProducts.mk"
    echo "Restored: AndroidProducts.mk"
  fi

  rm -rf "$STATE_DIR"
  echo "TWRP compat layer REMOVED — tree restored"
}

case "$CMD" in
  apply) apply_compat ;;
  restore) restore_compat ;;
  *) echo "Unknown command: $CMD (use apply|restore)"; exit 1 ;;
esac
