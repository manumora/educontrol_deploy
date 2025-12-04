#!/bin/bash

# Script de instalación del módulo Puppet educontrol_agent
# Autor: Manuel Mora Gordillo
# Fecha: 2025

set -e  # Detener el script si hay algún error

# Colores para mensajes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sin color

# Función para mostrar mensajes
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[ADVERTENCIA]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ========================================
# 1. VERIFICAR USUARIO ROOT
# ========================================
log_info "Verificando permisos de usuario..."
if [ "$EUID" -ne 0 ]; then 
    log_error "Este script debe ejecutarse como root"
    log_warning "Por favor, ejecuta: sudo $0"
    exit 1
fi
log_success "Usuario root verificado"

# ========================================
# 2. VERIFICAR DIRECTORIOS REQUERIDOS
# ========================================
log_info "Verificando directorios de Puppet..."
PUPPET_MODULES_DIR="/etc/puppetlabs/code/environments/production/modules"

if [ ! -d "$PUPPET_MODULES_DIR" ]; then
    log_error "No se encontró el directorio de módulos de Puppet"
    log_error "Ruta esperada: $PUPPET_MODULES_DIR"
    exit 1
fi
log_success "Directorio de módulos encontrado"

# ========================================
# 3. DESCARGAR ARCHIVO
# ========================================
log_info "Descargando archivo educontrol_agent.zip..."
DOWNLOAD_URL="https://github.com/manumora/educontrol_deploy/raw/refs/heads/main/agent/educontrol_agent.zip"
ZIP_FILE="/tmp/educontrol_agent.zip"

if ! curl -fsSL -o "$ZIP_FILE" "$DOWNLOAD_URL"; then
    log_error "Error al descargar el archivo"
    exit 1
fi

if [ ! -f "$ZIP_FILE" ]; then
    log_error "El archivo no se descargó correctamente"
    exit 1
fi

log_success "Archivo descargado correctamente en $ZIP_FILE"

# ========================================
# 4. VERIFICAR DISPONIBILIDAD DE UNZIP
# ========================================
log_info "Verificando disponibilidad de unzip..."
if ! command -v unzip &> /dev/null; then
    log_error "unzip no está instalado"
    log_info "Por favor, instala unzip primero:"
    log_info "  En Debian/Ubuntu: apt-get install unzip"
    exit 1
fi
log_success "unzip está disponible"

# ========================================
# 5. DESCOMPRIMIR ARCHIVO
# ========================================
log_info "Descomprimiendo archivo en $PUPPET_MODULES_DIR..."
if ! unzip -o "$ZIP_FILE" -d "$PUPPET_MODULES_DIR"; then
    log_error "Error al descomprimir el archivo"
    exit 1
fi
log_success "Archivo descomprimido correctamente"

# ========================================
# 6. VERIFICAR INSTALACIÓN
# ========================================
log_info "Verificando la instalación del módulo..."
if [ ! -d "$PUPPET_MODULES_DIR/educontrol_agent" ]; then
    log_warning "El directorio educontrol_agent no se encontró después de la descompresión"
    log_info "Contenido del directorio de módulos:"
    ls -la "$PUPPET_MODULES_DIR/" | tail -10
else
    log_success "Módulo educontrol_agent instalado correctamente"
fi

# ========================================
# 7. LIMPIAR ARCHIVO DESCARGADO
# ========================================
log_info "Limpiando archivos temporales..."
rm -f "$ZIP_FILE"
log_success "Archivos temporales eliminados"

# ========================================
# 8. MOSTRAR INFORMACIÓN AL USUARIO
# ========================================
echo ""
echo "=========================================="
echo "INSTALACIÓN COMPLETADA"
echo "=========================================="
echo ""
log_success "El módulo educontrol_agent ha sido instalado correctamente"
echo ""
echo "PRÓXIMOS PASOS:"
echo "==============="
echo ""
echo "1. Añade la siguiente línea a la configuración de tus nodos:"
echo ""
echo "   ${YELLOW}include educontrol_agent${NC}"
echo ""
echo "2. Aplica los cambios en el cliente Puppet:"
echo "   ${YELLOW}puppet agent -t${NC}"
echo ""
echo "3. Verifica los logs si hay algún problema:"
echo "   ${YELLOW}puppet agent -t --debug${NC}"
echo ""
echo "=========================================="
echo ""
log_success "Script de instalación finalizado"
