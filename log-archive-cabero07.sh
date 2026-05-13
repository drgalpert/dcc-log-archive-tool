#!/bin/bash

# ============================================================
# Log Archive Tool
# Autor: cabero07
# Descripción:
#   Comprime un directorio de logs dado, lo guarda en una
#   carpeta destino con nombre fechado y registra la operación.
# ============================================================

# ---------- Configuración inicial ----------
CURRENT_USER=$(whoami)

# Función de ayuda
show_usage() {
    echo "Uso: $0 <directorio-logs> [directorio-destino] [--clean]"
    echo ""
    echo "  <directorio-logs>      : directorio que quieres archivar (obligatorio)"
    echo "  [directorio-destino]   : carpeta donde guardar el .tar.gz (opcional, por defecto: ./archives)"
    echo "  --clean                : borra el directorio original tras archivarlo (opcional)"
    echo ""
    echo "Ejemplo: $0 /var/log"
    echo "         $0 /var/log /backups/logs --clean"
    exit 1
}

# ---------- Captura de argumentos ----------
if [ $# -eq 0 ]; then
    show_usage
fi

LOG_DIR="$1"                          # Directorio de origen
DEST_DIR="${2:-./archives}"           # Si no dan 2º argumento, se usa ./archives
CLEAN_MODE=false                      # Por defecto no borramos nada

# Revisamos si hay un tercer argumento (--clean)
if [ "$3" = "--clean" ]; then
    CLEAN_MODE=true
fi

# ---------- Verificaciones previas ----------
# ¿Existe el directorio de logs?
if [ ! -d "$LOG_DIR" ]; then
    echo "Error: '$LOG_DIR' no es un directorio válido."
    exit 2
fi

# Permisos de lectura
if [ ! -r "$LOG_DIR" ]; then
    echo "Error: no tienes permisos para leer '$LOG_DIR'."
    exit 3
fi

# Mostrar cabecera del informe
clear
echo "=============================================="
echo "  LOG ARCHIVE TOOL"
echo "  Ejecutado por : $CURRENT_USER"
echo "  Fecha         : $(date)"
echo "=============================================="
echo ""

# ---------- Tamaño antes de comprimir (stretch 1) ----------
echo "Calculando tamaño de '$LOG_DIR'..."
size_before=$(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)
if [ -n "$size_before" ]; then
    echo "Tamaño antes de comprimir : $size_before"
else
    echo "No se pudo calcular el tamaño (permisos insuficientes)."
fi

# ---------- Crear carpeta destino si no existe ----------
mkdir -p "$DEST_DIR" || {
    echo "Error: no se pudo crear el directorio destino '$DEST_DIR'."
    exit 4
}

# ---------- Nombre del archivo con timestamp ----------
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="$DEST_DIR/$ARCHIVE_NAME"

# ---------- Compresión (core) ----------
echo ""
echo "Comprimiendo '$LOG_DIR' en '$ARCHIVE_PATH'..."

# La opción -C cambia de carpeta antes de empaquetar para eliminar rutas absolutas
tar -czf "$ARCHIVE_PATH" -C "$(dirname "$LOG_DIR")" "$(basename "$LOG_DIR")"

if [ $? -eq 0 ]; then
    echo "Compresión exitosa."
else
    echo "Error durante la compresión."
    exit 5
fi

# ---------- Tamaño después de comprimir ----------
size_after=$(du -sh "$ARCHIVE_PATH" 2>/dev/null | cut -f1)
if [ -n "$size_after" ]; then
    echo "Tamaño del archivo comprimido : $size_after"
fi

# ---------- Registro de actividad (core) ----------
LOG_FILE="$DEST_DIR/archive_log.txt"
echo "$(date '+%Y-%m-%d %H:%M:%S') - $ARCHIVE_NAME" >> "$LOG_FILE"
echo "Operación registrada en '$LOG_FILE'."

# ---------- Opción de borrado (stretch 2) ----------
if [ "$CLEAN_MODE" = true ]; then
    echo ""
    echo "Opción --clean activada. Borrando contenido original..."
    read -p "¿Estás seguro de borrar '$LOG_DIR' definitivamente? (s/n): " confirm
    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
        rm -rf "$LOG_DIR"
        echo "Directorio '$LOG_DIR' eliminado."
    else
        echo "Borrado cancelado. El directorio original se ha conservado."
    fi
fi

echo ""
echo "=============================================="
echo "  ARCHIVADO COMPLETADO CON ÉXITO"
echo "=============================================="