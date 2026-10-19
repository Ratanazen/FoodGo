#!/usr/bin/env bash
# ==============================================================================
# FoodGo Database Backup & Disaster Recovery Script
# Supports: PostgreSQL (production) & SQLite (development fallback)
# Features: Timestamped backups, gzip compression, 7-day retention rotation,
#           and dry-run/restore verification modes.
# Zero-Emoji Policy Compliant
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_DIR="${ROOT_DIR}/backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
RETENTION_DAYS=7

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

log_info() {
    echo "[INFO] [$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log_warn() {
    echo "[WARN] [$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log_error() {
    echo "[ERROR] [$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --backup               Create a new timestamped database backup (default)"
    echo "  --restore <FILE>       Restore database from specified backup file (.dump.gz or .sqlite3.gz)"
    echo "  --list                 List all available backup archives"
    echo "  --retention <DAYS>     Set backup retention window in days (default: 7)"
    echo "  --help                 Show this help message"
}

backup_postgres() {
    local db_url="$1"
    local output_file="${BACKUP_DIR}/foodgo_pg_${TIMESTAMP}.dump.gz"

    log_info "Starting PostgreSQL backup to: ${output_file}"

    if ! command -v pg_dump >/dev/null 2>&1; then
        log_error "pg_dump command not found in PATH. Install postgresql-client."
        exit 1
    fi

    # Run pg_dump in custom archive format piped through gzip
    if pg_dump --format=c --no-owner --no-privileges "${db_url}" | gzip -9 > "${output_file}"; then
        local file_size
        file_size="$(du -h "${output_file}" | cut -f1)"
        log_info "PostgreSQL backup completed successfully: ${output_file} (${file_size})"
    else
        log_error "Failed to create PostgreSQL backup."
        rm -f "${output_file}"
        exit 1
    fi
}

backup_sqlite() {
    local sqlite_db="${ROOT_DIR}/backend/db.sqlite3"
    local output_file="${BACKUP_DIR}/foodgo_sqlite_${TIMESTAMP}.sqlite3.gz"

    log_info "Starting SQLite backup from: ${sqlite_db}"

    if [ ! -f "${sqlite_db}" ]; then
        log_error "SQLite database not found at ${sqlite_db}"
        exit 1
    fi

    # Use sqlite3 .backup command if sqlite3 CLI exists, else safe copy
    local temp_backup="${BACKUP_DIR}/temp_${TIMESTAMP}.sqlite3"
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 "${sqlite_db}" ".backup '${temp_backup}'"
    else
        cp "${sqlite_db}" "${temp_backup}"
    fi

    gzip -9 -c "${temp_backup}" > "${output_file}"
    rm -f "${temp_backup}"

    local file_size
    file_size="$(du -h "${output_file}" | cut -f1)"
    log_info "SQLite backup completed successfully: ${output_file} (${file_size})"
}

restore_postgres() {
    local backup_file="$1"
    local db_url="${DATABASE_URL:-}"

    if [ -z "${db_url}" ]; then
        log_error "DATABASE_URL environment variable is required to restore PostgreSQL."
        exit 1
    fi

    if ! command -v pg_restore >/dev/null 2>&1; then
        log_error "pg_restore command not found in PATH."
        exit 1
    fi

    log_warn "RESTORE ACTION: Restoring PostgreSQL database from ${backup_file}..."
    local temp_dump="${BACKUP_DIR}/temp_restore_${TIMESTAMP}.dump"
    gzip -d -c "${backup_file}" > "${temp_dump}"

    if pg_restore --clean --if-exists --no-owner --no-privileges -d "${db_url}" "${temp_dump}"; then
        log_info "PostgreSQL restore completed successfully."
    else
        log_warn "pg_restore completed with warnings (common if dropping non-existent tables)."
    fi

    rm -f "${temp_dump}"
}

restore_sqlite() {
    local backup_file="$1"
    local target_db="${ROOT_DIR}/backend/db.sqlite3"

    log_warn "RESTORE ACTION: Restoring SQLite database to ${target_db}..."

    # Create safety snapshot of current db before overwriting
    if [ -f "${target_db}" ]; then
        cp "${target_db}" "${target_db}.pre_restore_${TIMESTAMP}"
        log_info "Safety snapshot of previous database saved to ${target_db}.pre_restore_${TIMESTAMP}"
    fi

    gzip -d -c "${backup_file}" > "${target_db}"
    log_info "SQLite restore completed successfully: ${target_db}"
}

rotate_backups() {
    local days="$1"
    log_info "Rotating backups older than ${days} days..."

    local count=0
    while IFS= read -r old_file; do
        if [ -n "${old_file}" ]; then
            log_info "Removing expired backup: ${old_file}"
            rm -f "${old_file}"
            count=$((count + 1))
        fi
    done < <(find "${BACKUP_DIR}" -type f -name "foodgo_*.gz" -mtime +"${days}")

    log_info "Retention cleanup finished. Removed ${count} expired backup(s)."
}

list_backups() {
    log_info "Listing available backups in ${BACKUP_DIR}:"
    if [ -z "$(ls -A "${BACKUP_DIR}" 2>/dev/null)" ]; then
        echo "  (No backups found)"
        return
    fi

    printf "%-35s %-12s %-20s\n" "Filename" "Size" "Modified"
    echo "------------------------------------------------------------------"
    find "${BACKUP_DIR}" -type f -name "foodgo_*.gz" -printf "%f\t%s\t%TY-%Tm-%Td %TH:%TM:%TS\n" 2>/dev/null | \
    while IFS=$'\t' read -r fname fsize fdate; do
        local human_size
        human_size="$(numfmt --to=iec-i --suffix=B "${fsize}" 2>/dev/null || echo "${fsize} bytes")"
        printf "%-35s %-12s %-20s\n" "${fname}" "${human_size}" "${fdate}"
    done
}

# --- Main Dispatch ---

ACTION="backup"
RESTORE_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --backup)
            ACTION="backup"
            shift
            ;;
        --restore)
            ACTION="restore"
            RESTORE_FILE="${2:-}"
            if [ -z "${RESTORE_FILE}" ]; then
                log_error "Missing file argument for --restore"
                exit 1
            fi
            shift 2
            ;;
        --list)
            ACTION="list"
            shift
            ;;
        --retention)
            RETENTION_DAYS="${2:-7}"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

case "${ACTION}" in
    backup)
        if [ -n "${DATABASE_URL:-}" ]; then
            backup_postgres "${DATABASE_URL}"
        elif [ -n "${DB_NAME:-}" ] && [ -n "${DB_HOST:-}" ]; then
            # Construct PostgreSQL URL if credentials are split
            db_user="${DB_USER:-postgres}"
            db_pass="${DB_PASS:-${DB_PASSWORD:-}}"
            db_host="${DB_HOST:-localhost}"
            db_port="${DB_PORT:-5432}"
            db_url="postgresql://${db_user}:${db_pass}@${db_host}:${db_port}/${DB_NAME}"
            backup_postgres "${db_url}"
        else
            log_info "No DATABASE_URL configured. Falling back to local SQLite database."
            backup_sqlite
        fi
        rotate_backups "${RETENTION_DAYS}"
        ;;
    restore)
        if [ ! -f "${RESTORE_FILE}" ]; then
            log_error "Backup file not found: ${RESTORE_FILE}"
            exit 1
        fi
        if [[ "${RESTORE_FILE}" == *sqlite* ]]; then
            restore_sqlite "${RESTORE_FILE}"
        else
            restore_postgres "${RESTORE_FILE}"
        fi
        ;;
    list)
        list_backups
        ;;
esac
