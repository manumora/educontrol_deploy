#!/bin/bash

##############################################################################
# EduControl Agent - Instalador Manual (Sin Puppet)
# ---------------------------------------------------------
# Proyecto:     EduControl Deploy
# Repositorio:  [https://github.com/manumora/educontrol_deploy](https://github.com/manumora/educontrol_deploy)
# Autores:      Javier Alfonso de las Heras
# Fecha:        2026
# 
# Descripción:  Script para la instalación y configuración del agente en
#               clientes o servidores de forma independiente a Puppet.
##############################################################################
set -e

# Colores para la interfaz
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }


# URL pública del script para auto-re-ejecución
SCRIPT_URL="https://raw.githubusercontent.com/manumora/educontrol_deploy/main/agent/install_agent_manual.sh"

# Manejo de ejecución vía pipe (curl | bash)
if [ ! -t 0 ] && [ "${_AGENT_INSTALL_REEXEC:-0}" != "1" ]; then
    log_info "Detectado lanzamiento via pipe. Re-ejecutando desde fichero temporal..."
    TMPSCRIPT=$(mktemp /tmp/install_agent_XXXXXX.sh)
    curl -fsSL "${SCRIPT_URL}" -o "${TMPSCRIPT}"
    chmod +x "${TMPSCRIPT}"
    export _AGENT_INSTALL_REEXEC=1
    exec bash "${TMPSCRIPT}" </dev/tty
    exit 1
fi

# 1. Verificación de root
if [ "$EUID" -ne 0 ]; then
    log_error "Este script debe ejecutarse con sudo."
    exit 1
fi

echo -e "${YELLOW}--- Configuración de Parámetros EduControl ---${NC}"

# 2. Solicitar datos variables
read -p "Introduce el Host/IP del servidor: " HOST
while [[ -z "$HOST" ]]; do
    log_error "El Host/IP del servidor es obligatorio."
    read -p "Introduce el Host/IP del servidor: " HOST
done

read -p "Introduce el Token del Agente: " TOKEN
while [[ -z "$TOKEN" ]]; do
    log_error "El Token es obligatorio."
    read -p "Introduce el Token del Agente: " TOKEN
done

# 3. Variables de instalación
VERSION=$(curl -fsSL https://raw.githubusercontent.com/manumora/educontrol_deploy/refs/heads/main/version)

if [ -z "$VERSION" ]; then
    log_error "Error: No se pudo obtener la versión."
    exit 1
fi

REPO_URL="https://raw.githubusercontent.com/manumora/educontrol_deploy/main/agent/educontrol_agent/files"
DEB_FILE="educontrol-agent_${VERSION}_all.deb"
CONFIG_PATH="/etc/educontrol/agent_config.json"

# 4. Descarga e Instalación
log_info "Descargando paquete v${VERSION}..."
wget -q "${REPO_URL}/${DEB_FILE}" -O "/tmp/${DEB_FILE}"

log_info "Instalando dependencias y paquete..."
apt update
apt install "/tmp/${DEB_FILE}" -y

# 5. Configuración
log_info "Configurando agent_config.json..."

sed -i "s/AQUI_IP_SERVIDOR_EDUCONTROL/${HOST}/g" "$CONFIG_PATH"
sed -i "s/AQUI_TU_API_TOKEN/${TOKEN}/g" "$CONFIG_PATH"

# 6. Servicio
log_info "Reiniciando servicio..."
systemctl restart educontrol-agent

# Limpieza
rm "/tmp/${DEB_FILE}"

echo -e "\n${GREEN}==========================================${NC}"
log_success "Instalación completada y configurada."
echo -e "Host: ${BLUE}${HOST}${NC}"
echo -e "Puertos: ${BLUE}7579${NC}"
echo -e "SSL: ${BLUE}Enabled (Verify: False)${NC}"
echo -e "${GREEN}==========================================${NC}\n"

systemctl status educontrol-agent --no-pager | grep "Active:"
