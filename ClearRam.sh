#!/bin/bash
# ClearRam.sh — Clear Linux RAM cache and show memory summary
# Author: Julio Mauro <julio.mauro@gmail.com>
#
# Usage: sudo ./ClearRam.sh [-d LEVEL] [-n]
#   -d  Drop cache level: 1=page cache, 2=dentries+inodes, 3=all (default: 3)
#   -n  Dry run — show memory info without clearing

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Defaults ──────────────────────────────────────────────────
DROP_LEVEL=3
DRY_RUN=false

# ── Help ──────────────────────────────────────────────────────
usage() {
  echo -e "${BOLD}Usage:${RESET} sudo $0 [-d LEVEL] [-n]"
  echo ""
  echo -e "  ${CYAN}-d${RESET}  Drop cache level (default: 3)"
  echo -e "        ${BOLD}1${RESET} — page cache only"
  echo -e "        ${BOLD}2${RESET} — dentries and inodes"
  echo -e "        ${BOLD}3${RESET} — page cache + dentries + inodes (full)"
  echo -e "  ${CYAN}-n${RESET}  Dry run — show memory info without clearing"
  echo ""
  echo -e "${BOLD}Examples:${RESET}"
  echo -e "  sudo $0               # full cache clear"
  echo -e "  sudo $0 -d 1          # page cache only"
  echo -e "  sudo $0 -n            # dry run, no changes"
  exit 0
}

# ── Parse arguments ───────────────────────────────────────────
while getopts "d:nh" opt; do
  case "$opt" in
    d) DROP_LEVEL="$OPTARG" ;;
    n) DRY_RUN=true ;;
    h) usage ;;
    ?) usage ;;
  esac
done

# ── Must run as root ──────────────────────────────────────────
if [ "$DRY_RUN" = false ] && [ "$(id -u)" != "0" ]; then
  echo -e "${RED}Error:${RESET} this script must be run as root (use sudo)."
  exit 1
fi

# ── Validate drop level ───────────────────────────────────────
if ! [[ "$DROP_LEVEL" =~ ^[123]$ ]]; then
  echo -e "${RED}Error:${RESET} -d must be 1, 2, or 3 (got: '$DROP_LEVEL')"
  exit 1
fi

# ── Read memory values from /proc/meminfo ─────────────────────
meminfo() {
  grep "^${1}:" /proc/meminfo | awk '{printf "%.0f", $2 / 1024}'
}

print_memory() {
  local label="$1"
  local free
  local cached
  local available
  local total
  local swap_total
  local swap_free
  local swap_used

  total=$(meminfo MemTotal)
  free=$(meminfo MemFree)
  available=$(meminfo MemAvailable)
  cached=$(grep "^Cached:" /proc/meminfo | awk '{printf "%.0f", $2 / 1024}')
  buffers=$(meminfo Buffers)
  swap_total=$(meminfo SwapTotal)
  swap_free=$(meminfo SwapFree)
  swap_used=$(( swap_total - swap_free ))

  echo -e "  ${BOLD}${label}${RESET}"
  echo -e "  ────────────────────────────────────"
  echo -e "  Total RAM   : ${BOLD}${total} MiB${RESET}"
  echo -e "  Free        : ${BOLD}${free} MiB${RESET}"
  echo -e "  Available   : ${BOLD}${available} MiB${RESET}"
  echo -e "  Cached      : ${BOLD}${cached} MiB${RESET}"
  echo -e "  Buffers     : ${BOLD}${buffers} MiB${RESET}"
  if [ "$swap_total" -gt 0 ]; then
    echo -e "  Swap total  : ${BOLD}${swap_total} MiB${RESET}"
    echo -e "  Swap used   : ${BOLD}${swap_used} MiB${RESET}"
    echo -e "  Swap free   : ${BOLD}${swap_free} MiB${RESET}"
  else
    echo -e "  Swap        : ${YELLOW}not configured${RESET}"
  fi
  echo ""
}

drop_label() {
  case "$1" in
    1) echo "page cache" ;;
    2) echo "dentries + inodes" ;;
    3) echo "page cache + dentries + inodes" ;;
  esac
}

# ── Header ────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}  ClearRam — Linux Memory Cache Cleaner${RESET}"
echo -e "  $(date)"
echo ""

print_memory "Before"

# ── Dry run exit ──────────────────────────────────────────────
if [ "$DRY_RUN" = true ]; then
  echo -e "  ${YELLOW}Dry run — no changes made.${RESET}"
  echo -e "  Would drop: ${BOLD}$(drop_label $DROP_LEVEL)${RESET} (level ${DROP_LEVEL})\n"
  exit 0
fi

# ── Sync filesystem before dropping caches ────────────────────
echo -e "  Syncing filesystem..."
sync
if [ $? -ne 0 ]; then
  echo -e "${RED}Error:${RESET} sync failed. Aborting."
  exit 1
fi

# ── Drop caches ───────────────────────────────────────────────
echo -e "  Dropping caches: ${BOLD}$(drop_label $DROP_LEVEL)${RESET} (level ${DROP_LEVEL})..."
echo "$DROP_LEVEL" > /proc/sys/vm/drop_caches
if [ $? -ne 0 ]; then
  echo -e "${RED}Error:${RESET} failed to write to /proc/sys/vm/drop_caches."
  exit 1
fi

echo ""
print_memory "After"

# ── Summary ───────────────────────────────────────────────────
free_before=$(grep "^MemFree:" /proc/meminfo | awk '{printf "%.0f", $2 / 1024}')
available_after=$(meminfo MemAvailable)

echo -e "  ${GREEN}${BOLD}Done.${RESET} Available memory: ${BOLD}${available_after} MiB${RESET}\n"
