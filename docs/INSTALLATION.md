# EduControl Deploy

Repositorio de despliegue para el sistema EduControl.

## Instalación del Servidor EduControl

Para instalar el servidor EduControl, ejecuta el siguiente comando como root:

```bash
curl -fsSL https://raw.githubusercontent.com/manumora/educontrol_deploy/refs/heads/main/install_educontrol.sh | bash
```

### ¿Qué hace el script de instalación?

El script realizará automáticamente las siguientes acciones:

1. **Verifica e instala Docker Compose** si no está presente
2. **Crea el directorio de instalación** en `/var/docker/educontrol`
3. **Descarga los archivos de configuración** necesarios (docker-compose.yaml y plantilla .env)
4. **Solicita la configuración**:
   - Detecta automáticamente la IP del servidor EduControl
   - Pide la IP del servidor LDAP
   - Pide la contraseña del servidor LDAP
5. **Genera contraseñas seguras** para PostgreSQL y Django
6. **Crea los directorios** necesarios para los volúmenes de Docker
7. **Descarga e inicia los contenedores** de Docker

### Requisitos previos

- Sistema operativo: Linux (probado en Debian/Ubuntu)
- Docker instalado y funcionando
- Permisos de root
- Conexión a Internet para descargar las imágenes

### Acceso al servidor

Una vez completada la instalación, podrás acceder a EduControl en:

```
https://TU_IP_SERVIDOR:7579/
```

La configuración y credenciales se guardan en `/var/docker/educontrol/.env`

### Actualización del servidor

Para actualizar EduControl a una nueva versión, simplemente ejecuta el mismo comando de instalación:

```bash
curl -fsSL https://raw.githubusercontent.com/manumora/educontrol_deploy/refs/heads/main/install_educontrol.sh | sudo bash
```

El script detectará que el archivo `.env` ya existe y:
- **Mantendrá** toda la configuración existente (contraseñas, IPs, etc.)
- **Actualizará** el archivo `docker-compose.yaml` a la última versión
- **Descargará** las nuevas imágenes de Docker
- **Reiniciará** los contenedores con las nuevas versiones

No se perderán datos ni configuraciones durante la actualización.

[Volver](../README.md)
