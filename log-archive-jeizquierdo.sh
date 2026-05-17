#!/bin/bash

# Configuration
DEST_DIR="archives"
LOG_FILE="archive_log.txt"
RETENTION_DAYS=7
AUTO_CLEAN=false
SIZE_REPORT=false
LOG_DIR=""

# Help function
show_help() {
    echo "Usage: $0 <log-directory> [destination-directory] [options]"
    echo ""
    echo "Options:"
    echo "  --auto-clean     Delete original logs after successful archive"
    echo "  --size-report    Display directory size before and after compression"
    echo "  --retention N    Delete archives older than N days (default: 7)"
    echo "  --help           Show this help message"
    exit 0
}

# Process arguments
for arg in "$@"; do
    case "$arg" in
        --auto-clean)
            AUTO_CLEAN=true
            ;;
        --size-report)
            SIZE_REPORT=true
            ;;
        --help)
            show_help
            ;;
        --retention)
            # Next argument will be handled specially
            ;;
        *)
            # Check if it's a retention value
            if [ "$prev_arg" = "--retention" ]; then
                RETENTION_DAYS="$arg"
            # First non-flag argument is log directory
            elif [ -z "$LOG_DIR" ]; then
                LOG_DIR="$arg"
            # Second non-flag argument is destination directory
            elif [ "$DEST_DIR" = "archives" ]; then
                DEST_DIR="$arg"
            fi
            ;;
    esac
    prev_arg="$arg"
done

# Validate arguments
if [ -z "$LOG_DIR" ]; then
    echo "Error: Log directory must be specified"
    echo "Usage: $0 <log-directory> [destination-directory] [options]"
    exit 1
fi

# Check if directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo "Error: Directory '$LOG_DIR' does not exist"
    exit 1
fi

# Create archive directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
    mkdir -p "$DEST_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create destination directory '$DEST_DIR'"
        exit 1
    fi
fi

# Generate timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${DEST_DIR}/${ARCHIVE_NAME}"

# Size report before compression
if [ "$SIZE_REPORT" = true ]; then
    SIZE_BEFORE=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
    echo "Size before compression: $SIZE_BEFORE"
fi

# Compress logs
echo "Compressing logs from '$LOG_DIR'..."
CURRENT_DIR=$(pwd)
cd "$LOG_DIR" || exit 1
tar -czf "$CURRENT_DIR/$ARCHIVE_PATH" . 2>/dev/null
TAR_EXIT=$?
cd "$CURRENT_DIR" || exit 1

# Check if compression was successful
if [ $TAR_EXIT -eq 0 ] && [ -f "$ARCHIVE_PATH" ]; then
    # Size report after compression
    if [ "$SIZE_REPORT" = true ]; then
        SIZE_AFTER=$(du -sh "$ARCHIVE_PATH" 2>/dev/null | cut -f1)
        echo "Size after compression: $SIZE_AFTER"
    fi
    
    # Log the archive
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $ARCHIVE_NAME" >> "${DEST_DIR}/${LOG_FILE}"
    
    echo "✓ Logs archived successfully: $ARCHIVE_PATH"
    
    # Auto-clean: delete original logs
    if [ "$AUTO_CLEAN" = true ]; then
        echo "Deleting original logs..."
        rm -rf "$LOG_DIR"/*
        if [ $? -eq 0 ]; then
            echo "✓ Original logs deleted"
        else
            echo "⚠ Warning: Could not delete all original logs"
        fi
    fi
    
    # Retention policy: delete old archives
    if [ "$RETENTION_DAYS" -gt 0 ]; then
        echo "Applying retention policy ($RETENTION_DAYS days)..."
        DELETED_COUNT=0
        for file in "$DEST_DIR"/logs_archive_*.tar.gz; do
            if [ -f "$file" ]; then
                # Check if file is older than retention days
                if find "$file" -mtime +"$RETENTION_DAYS" | grep -q .; then
                    rm -f "$file"
                    DELETED_COUNT=$((DELETED_COUNT + 1))
                fi
            fi
        done
        
        if [ "$DELETED_COUNT" -gt 0 ]; then
            echo "✓ $DELETED_COUNT old archive(s) deleted"
        else
            echo "No archives to delete"
        fi
    fi
else
    echo "Error: Log compression failed"
    exit 1
fi
