#!/bin/bash

# Script de instalación de EduControl
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

# Función para generar contraseñas aleatorias
generate_password() {
    local length=$1
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Función para generar Django Secret Key
generate_django_secret() {
    openssl rand -base64 64 | tr -d "=+/" | cut -c1-50
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
# 2. VERIFICAR E INSTALAR DOCKER COMPOSE
# ========================================
log_info "Verificando instalación de Docker Compose..."

if command -v docker compose &> /dev/null; then
    log_success "Docker Compose ya está instalado"
    docker compose version
elif command -v docker-compose &> /dev/null; then
    log_success "Docker Compose (versión standalone) ya está instalado"
    docker-compose version
else
    log_warning "Docker Compose no está instalado. Procediendo a instalar..."
    
    # Verificar si Docker está instalado
    if ! command -v docker &> /dev/null; then
        log_error "Docker no está instalado. Por favor, instala Docker primero."
        log_info "Visita: https://docs.docker.com/engine/install/"
        exit 1
    fi
    
    # Instalar Docker Compose plugin
    log_info "Instalando Docker Compose plugin..."
    DOCKER_CONFIG=${DOCKER_CONFIG:-/usr/local/lib/docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    
    # Detectar arquitectura
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="x86_64"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            ;;
        *)
            log_error "Arquitectura no soportada: $ARCH"
            exit 1
            ;;
    esac
    
    # Descargar última versión de Docker Compose
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}" \
         -o $DOCKER_CONFIG/cli-plugins/docker-compose
    
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    log_success "Docker Compose instalado correctamente"
    docker compose version
fi

# ========================================
# 3. CREAR CARPETA EN RAÍZ
# ========================================
log_info "Creando directorio /docker/educontrol"
INSTALL_DIR="/docker/educontrol"

if [ -d "$INSTALL_DIR" ]; then
    log_warning "El directorio $INSTALL_DIR ya existe"
else
    mkdir -p "$INSTALL_DIR"
    log_success "Directorio $INSTALL_DIR creado"
fi

cd "$INSTALL_DIR"

# ========================================
# 4. DESCARGAR ARCHIVOS
# ========================================
log_info "Descargando archivos de configuración..."

REPO_URL="https://raw.githubusercontent.com/manumora/educontrol_deploy/refs/heads/main"

# Descargar docker-compose.yaml
log_info "Descargando docker-compose.yaml..."
curl -fsSL "${REPO_URL}/docker-compose.yaml" -o docker-compose.yaml
log_success "docker-compose.yaml descargado"

# Crear .env si no existe
if [ ! -f ".env" ]; then
    log_info "Descargando plantilla de configuración .env..."
    curl -fsSL "${REPO_URL}/env.example" -o .env
    log_success "Archivo .env creado"

    # ========================================
    # 6. SOLICITAR DATOS AL USUARIO
    # ========================================
    echo ""
    echo "=========================================="
    echo "CONFIGURACIÓN DE EDUCONTROL"
    echo "=========================================="
    echo ""

    # Detectar IP del servidor automáticamente
    log_info "Detectando IP del servidor..."
    SERVER_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$SERVER_IP" ]; then
        # Intento alternativo si hostname -I no funciona
        SERVER_IP=$(ip route get 1 | awk '{print $7;exit}')
    fi
    if [ -z "$SERVER_IP" ]; then
        log_warning "No se pudo detectar la IP automáticamente"
        read -p "Ingresa la IP o dominio del servidor manualmente: " SERVER_IP
        while [ -z "$SERVER_IP" ]; do
            log_warning "La IP/dominio no puede estar vacía"
            read -p "Ingresa la IP o dominio del servidor: " SERVER_IP
        done
    else
        log_success "IP del servidor detectada: $SERVER_IP"
    fi

    # IP servidor LDAP
    read -p "Ingresa la IP del servidor LDAP: " LDAP_SERVER
    while [ -z "$LDAP_SERVER" ]; do
        log_warning "La IP del servidor LDAP no puede estar vacía"
        read -p "Ingresa la IP del servidor LDAP: " LDAP_SERVER
    done

    # Contraseña servidor LDAP
    read -sp "Ingresa la contraseña del servidor LDAP: " LDAP_PASSWORD
    echo ""
    while [ -z "$LDAP_PASSWORD" ]; do
        log_warning "La contraseña LDAP no puede estar vacía"
        read -sp "Ingresa la contraseña del servidor LDAP: " LDAP_PASSWORD
        echo ""
    done

    # ========================================
    # 7. GENERAR PASSWORDS ALEATORIOS
    # ========================================
    log_info "Generando contraseñas seguras..."
    POSTGRES_PASSWORD=$(generate_password 32)
    DJANGO_SECRET_KEY=$(generate_django_secret)
    log_success "Contraseñas generadas"

    # ========================================
    # 8. RELLENAR .env CON LA INFORMACIÓN
    # ========================================
    log_info "Configurando archivo .env..."

    # Usar awk para reemplazar valores de forma segura con cualquier carácter especial
    awk -v pg_pass="$POSTGRES_PASSWORD" \
        -v dj_key="$DJANGO_SECRET_KEY" \
        -v server_ip="$SERVER_IP" \
        -v ldap_srv="$LDAP_SERVER" \
        -v ldap_pass="$LDAP_PASSWORD" '
    {
        if ($0 ~ /^POSTGRES_PASSWORD=/) {
            print "POSTGRES_PASSWORD=" pg_pass
        } else if ($0 ~ /^DJANGO_SECRET_KEY=/) {
            print "DJANGO_SECRET_KEY=" dj_key
        } else if ($0 ~ /^DJANGO_ALLOWED_HOSTS=/) {
            print "DJANGO_ALLOWED_HOSTS=localhost 127.0.0.1 " server_ip
        } else if ($0 ~ /^CSRF_TRUSTED_ORIGINS=/) {
            print "CSRF_TRUSTED_ORIGINS=http://" server_ip ":7579 https://" server_ip ":7579"
        } else if ($0 ~ /^CORS_ALLOWED_ORIGINS=/) {
            print "CORS_ALLOWED_ORIGINS=http://" server_ip ":7579 https://" server_ip ":7579"
        } else if ($0 ~ /^AUTH_LDAP_SERVER=/) {
            print "AUTH_LDAP_SERVER=" ldap_srv
        } else if ($0 ~ /^AUTH_LDAP_PASSWORD=/) {
            print "AUTH_LDAP_PASSWORD=" ldap_pass
        } else {
            print $0
        }
    }' .env > .env.tmp && mv .env.tmp .env

    log_success "Archivo .env configurado correctamente"

    # ========================================
    # 9. CREAR DIRECTORIOS NECESARIOS
    # ========================================
    log_info "Creando directorios para volúmenes..."
    mkdir -p postgresql redis backend/staticfiles backend/media frontend/nginx/conf.d frontend/staticfiles frontend/letsencrypt
    log_success "Directorios creados"

    # ========================================
    # 10. MOSTRAR RESUMEN
    # ========================================
    echo ""
    echo "=========================================="
    echo "RESUMEN DE CONFIGURACIÓN"
    echo "=========================================="
    echo "Directorio de instalación: $INSTALL_DIR"
    echo "Servidor EduControl: $SERVER_IP"
    echo "Servidor LDAP: $LDAP_SERVER"
    echo "Contraseña PostgreSQL: [GENERADA ALEATORIAMENTE]"
    echo "Django Secret Key: [GENERADA ALEATORIAMENTE]"
    echo "=========================================="
    echo ""
else
    log_warning "El archivo .env ya existe. Se omite la configuración."
    log_info "Si deseas reconfigurar, elimina el archivo .env y ejecuta el script nuevamente."
    
    # ========================================
    # 9. CREAR DIRECTORIOS NECESARIOS
    # ========================================
    log_info "Creando directorios para volúmenes..."
    mkdir -p postgresql redis backend/staticfiles backend/media frontend/nginx/conf.d frontend/staticfiles frontend/letsencrypt
    log_success "Directorios creados"
fi

# ========================================
# 11. INICIO DE CONTENEDORES
# ========================================
log_info "Iniciando contenedores de EduControl..."
echo ""

# Descargar imágenes primero
log_info "Descargando imágenes de Docker..."
docker compose pull

# Iniciar contenedores
log_info "Levantando servicios..."
docker compose up -d

echo ""
log_success "¡EduControl está iniciando!"
echo ""
echo "=========================================="
echo "PRÓXIMOS PASOS"
echo "=========================================="
echo "1. Verifica el estado de los contenedores:"
echo "   docker compose ps"
echo ""
echo "2. Verifica los logs si hay algún problema:"
echo "   docker compose logs -f"
echo ""
echo "3. Accede a EduControl en:"
echo "   http://${SERVER_IP}:7579/"
echo ""
echo "4. Las credenciales y configuración están en:"
echo "   ${INSTALL_DIR}/.env"
echo ""
echo "=========================================="

echo ""
log_success "Script de instalación finalizado"
