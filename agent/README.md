# Instalación del Agente EduControl

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

1. Edita el archivo de configuración de tus nodos (por ejemplo, `/etc/puppetlabs/code/environments/production/manifests/site.pp`)

2. Añade `include educontrol_agent` a la configuración de los nodos donde quieres instalar el agente:

2. Reinicia el servidor Puppet:
   ```bash
   systemctl restart puppetserver
   ```

4. Aplica los cambios en los clientes Puppet:
   ```bash
   puppet agent -t
   ```
