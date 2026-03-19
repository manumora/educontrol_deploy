# Instalación Manual del Agente EduControl

**Autor del script:** Javier Alfonso de las Heras

Este documento detalla el proceso de instalación y configuración manual del agente EduControl en equipos Linux, útil para entornos donde no se disponga de Puppet o para instalaciones aisladas.

## Requisitos Previos

Antes de comenzar la instalación, asegúrate de tener:

1.  **IP o Host del servidor EduControl**: La dirección donde está instalado el panel de control.
2.  **Token de API**: Debes generar un token en el servidor EduControl accediendo a **Configuración -> Tokens API**.
3.  **Permisos de root**: El script debe ejecutarse con `sudo`.

## Instalación Rápida

Para instalar el agente mediante el script automatizado, ejecuta el siguiente comando como root:

```bash
curl -fsSL https://raw.githubusercontent.com/manumora/educontrol_deploy/main/agent/install_agent_manual.sh | bash
```

### ¿Qué hace este script?

1.  **Validación de entrada**: Te solicitará interactivamente la IP del servidor y el Token.
2.  **Descarga**: Obtiene la última versión del paquete `.deb` directamente desde el repositorio oficial.
3.  **Instalación**: Instala el paquete y sus dependencias mediante `apt`.
4.  **Configuración**: Edita el archivo `/etc/educontrol/agent_config.json` sustituyendo los valores predeterminados por los que hayas introducido.
5.  **Servicio**: Reinicia el servicio `educontrol-agent` mediante `systemctl`.
6.  **Limpieza**: Elimina los archivos temporales de instalación.

## Comprobación del estado

Una vez finalizado el script, puedes verificar que el agente está funcionando correctamente con el siguiente comando:

```bash
systemctl status educontrol-agent
```

El agente debería aparecer como `active (running)`.

## Configuración Manual Posterior

Si necesitas cambiar la IP del servidor o el token en el futuro, puedes editar directamente el archivo de configuración:

```bash
nano /etc/educontrol/agent_config.json
```

Tras realizar cualquier cambio, es necesario reiniciar el servicio:

```bash
systemctl restart educontrol-agent
```

[Volver](../README.md)
