#!/bin/bash
set -euo pipefail

# Simple log archiver implementing the course requirements

PROG_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage: $PROG_NAME <log-directory> [destination] [options]

Positional:
  <log-directory>    Directory containing logs to archive (required)
  [destination]      Directory to put archives (default: archives/)

Options:
  -r, --remove       Remove original logs after successful archive (auto-clean)
  -k, --keep         Keep old archives (disable retention cleanup)
  -h, --help         Show this help and exit

Example:
  ./log-archive-drgalpert.sh /var/log
  ./log-archive-drgalpert.sh /var/log /mnt/backups -r
EOF
}

if [ $# -lt 1 ]; then
  usage
  exit 2
fi

# Defaults
REMOVE_ORIG=0
KEEP_OLD=0
SOURCE_DIR=""
DEST_DIR="archives"

# Extract first positional arg as source
SOURCE_DIR=$1
shift || true

# If next arg exists and doesn't start with '-', treat as destination
if [ $# -gt 0 ] && [[ $1 != -* ]]; then
  DEST_DIR=$1
  shift || true
fi

# Parse remaining flags
while [ $# -gt 0 ]; do
  case "$1" in
    -r|--remove)
      REMOVE_ORIG=1
      shift
      ;;
    -k|--keep)
      KEEP_OLD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Normalize paths (realpath may not exist on all systems)
if command -v realpath >/dev/null 2>&1; then
  SOURCE_DIR=$(realpath -m "$SOURCE_DIR")
  DEST_DIR=$(realpath -m "$DEST_DIR")
else
  # fallback: remove trailing slash only
  SOURCE_DIR=${SOURCE_DIR%/}
  DEST_DIR=${DEST_DIR%/}
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Source directory does not exist or is not a directory: $SOURCE_DIR" >&2
  exit 3
fi

mkdir -p "$DEST_DIR"

timestamp=$(date +%Y%m%d_%H%M%S)
archive_name="logs_archive_${timestamp}.tar.gz"
archive_path="$DEST_DIR/$archive_name"
log_file="$DEST_DIR/archive_log.txt"

echo "Archiving '$SOURCE_DIR' -> '$archive_path'"

# Size before
size_before=$(du -sh "$SOURCE_DIR" 2>/dev/null | awk '{print $1}') || size_before="N/A"

# Create tar.gz of the contents of the directory (preserve relative paths inside)
tar -czf "$archive_path" -C "$SOURCE_DIR" .

if [ $? -ne 0 ] || [ ! -f "$archive_path" ]; then
  echo "Archive creation failed." >&2
  exit 4
fi

# Size after
size_after=$(du -h "$archive_path" 2>/dev/null | awk '{print $1}') || size_after="N/A"

# Log activity
if date --iso-8601=seconds >/dev/null 2>&1; then
  timestamp_log=$(date --iso-8601=seconds)
else
  timestamp_log=$(date)
fi
echo "$timestamp_log  $archive_name  from: $SOURCE_DIR  size_before: $size_before  size_archive: $size_after" >> "$log_file"

echo "Archive created: $archive_path"
echo "Size before: $size_before  Archive size: $size_after"
echo "Logged to: $log_file"

if [ "$REMOVE_ORIG" -eq 1 ]; then
  echo "Removing original files in $SOURCE_DIR (user requested)"
  # Remove contents but keep the directory itself
  # Use a safe removal that handles hidden files
  if [ -n "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]; then
    rm -rf "$SOURCE_DIR"/* "$SOURCE_DIR"/.[!.]* 2>/dev/null || true
  fi
  echo "Original files removed."
fi

# Retention: delete archives older than 7 days unless KEEP_OLD is set
if [ "$KEEP_OLD" -eq 0 ]; then
  echo "Applying retention: removing archives older than 7 days in $DEST_DIR"
  find "$DEST_DIR" -maxdepth 1 -type f -name 'logs_archive_*.tar.gz' -mtime +7 -print -exec rm -f {} \;
fi

echo "Done."

exit 0
