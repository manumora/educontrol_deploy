# Instalación del Agente EduControl

Este documento detalla el proceso de instalación y configuración del agente EduControl en los equipos cliente de forma centralizada mediante Puppet.

## Instalación del Módulo Puppet

Para instalar el módulo Puppet en tu servidor Puppet, ejecuta el siguiente comando como root:

```bash
curl -fsSL https://raw.githubusercontent.com/manumora/educontrol_deploy/refs/heads/main/agent/install_agent.sh | bash
```

Este script realizará automáticamente las siguientes acciones:

1. Descargará el módulo `educontrol_agent` desde el repositorio
2. Lo descomprimirá en `/etc/puppetlabs/code/environments/production/modules`
3. Te mostrará las instrucciones para configurar los nodos que pueden usar el agente

### Pasos posteriores

Después de ejecutar el script de instalación:

1. **Crear un API key** en el servidor EduControl accediendo a **Configuración -> Tokens API**.

2. **Configurar el agente**: Modifica el fichero `/etc/puppetlabs/code/environments/production/modules/educontrol_agent/files/agent_config.json` para:
   - Añadir el **API key** creado en el paso 1.
   - Configurar el **"host"** con la dirección IP del servidor EduControl.

3. **Editar la configuración de nodos**: Abre el archivo de configuración de tus nodos (por ejemplo, `/etc/puppetlabs/code/environments/production/modules/especifica_xubuntu2204/manifests/init.pp`).

4. **Añadir el módulo**: Incluye `include educontrol_agent` en la configuración de los nodos donde quieras desplegar el agente.

5. **Reinicia el servidor Puppet**:
   ```bash
   systemctl restart puppetserver
   ```

6. **Aplica los cambios en los clientes Puppet**:
   ```bash
   puppet agent -t
   ```
