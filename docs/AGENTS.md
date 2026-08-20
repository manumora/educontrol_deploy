# Módulo de Agentes

El módulo de Agentes de EduControl es la pieza fundamental para la comunicación y administración remota de los dispositivos de la red. Cada equipo cliente ejecuta un agente en segundo plano que permite realizar tareas avanzadas de gestión de forma centralizada.

## Funcionalidades Principales

### 1. Terminal Remota
A través del agente, el administrador puede abrir una sesión de terminal interactiva directamente contra el equipo remoto. Esto permite la ejecución de comandos en tiempo real, facilitando la resolución de problemas y la configuración del sistema operativo sin necesidad de desplazarse físicamente.


[![Hacer click para descargar video de demo](https://raw.githubusercontent.com/manumora/educontrol_deploy/main/docs/img/terminal_simple.png)](https://raw.githubusercontent.com/manumora/educontrol_deploy/main/docs/img/terminal_simple.mp4)

### 2. Administración Gráfica (VNC)
Para aquellos casos en los que se requiera interacción visual, el agente integra la posibilidad de iniciar una sesión VNC (Virtual Network Computing). Con este acceso remoto completo al escritorio, el administrador puede operar el equipo como si estuviera frente a él, brindando soporte directamente a los usuarios o configurando aplicaciones con interfaz gráfica.

[![Hacer click para descargar video de demo](https://raw.githubusercontent.com/manumora/educontrol_deploy/main/docs/img/vnc.png)](https://raw.githubusercontent.com/manumora/educontrol_deploy/main/docs/img/vnc.mp4)

### 3. Ejecución Simultánea de Comandos
EduControl permite la ejecución masiva de comandos u operaciones en múltiples agentes **simultáneamente**. Puedes seleccionar varios equipos a la vez y lanzar tareas administrativas sobre todos ellos, lo que reduce dramáticamente los tiempos de mantenimiento para laboratorios o aulas completas.

[![Hacer click para descargar video de demo](https://raw.githubusercontent.com/manumora/educontrol_deploy/main/docs/img/terminal_multiple.png)](https://raw.githubusercontent.com/manumora/educontrol_deploy/main/docs/img/terminal_multiple.mp4)

### 4. Sistema de Autorenombrado (Integración LDAP)
El agente posee una característica inteligente de autorenombrado. Durante su inicio el agente sigue la siguiente lógica de prioridad:

1. Consulta LDAP:
	- Si el equipo EXISTE en LDAP y el nombre COINCIDE con el actual del equipo → no hace nada, termina.
	- Si el equipo EXISTE en LDAP y el nombre NO coincide → renombra al equipo con el nombre de LDAP, actualiza el inventario y termina.

2. Si el equipo NO EXISTE en LDAP, consulta el inventario:
	- Si el hostname del inventario COINCIDE con el actual del equipo → no hace nada.
	- Si el hostname del inventario es DISTINTO al del equipo → renombra el equipo con el nombre del inventario.

Desde EduControl Server, en la sección de inventario, también es posible renombrar el `hostname` de un registro. Además:

- Si EduControl Agent está online el renombrado se aplicará de forma automática en el equipo.
- Si está offline, el cambio se aplicará en el siguiente inicio del agente.

![Edita hostname de un registro del inventario](https://raw.githubusercontent.com/manumora/educontrol_deploy/main/docs/img/edit_hostname.png)

Ten en cuenta que LDAP siempre tiene prioridad: si el equipo existe en LDAP, el nombre definido en LDAP prevalece sobre cualquier cambio realizado desde el inventario del servidor.

El comportamiento de autorenombrado puede habilitarse o deshabilitarse desde la configuración del agente mediante la opción `auto_rename` en `agent_config.json`.

### 5. Resolución de Problemas de Certificados (Puppet)
El agente de EduControl monitoriza proactivamente el estado del agente **Puppet**. Si detecta que este se encuentra bloqueado por problemas de certificados, el sistema actúa de forma automática:
- **Limpieza Local:** El agente borra el certificado en el propio equipo.
- **Sincronización con el Servidor:** Se comunica la incidencia a EduControl Server, el cual envía los comandos necesarios al servidor principal para eliminar también allí el certificado, permitiendo que Puppet vuelva a funcionar correctamente de manera transparente.
- **Auditoría:** El bloqueo de Puppet y las acciones realizadas (limpieza local y sincronización con el servidor) se registran en el sistema de auditoría de EduControl, incluyendo marcas temporales y el identificador de la entidad que originó la acción.

![Puppet atascado](https://raw.githubusercontent.com/manumora/educontrol_deploy/refs/heads/main/docs/img/puppet_lock.png)

### 6. Aviso de Cambio de Contraseña al Iniciar Sesión
Cuando un profesor inicia sesión en un equipo, el agente puede consultar al servidor si debe cambiar su contraseña y, en caso afirmativo, abrirle el navegador directamente en la página de cambio.

El aviso se muestra por cualquiera de estos motivos, todos ellos derivados de la [política de contraseñas](./LDAP.md#políticas-de-contraseñas):

- **Debe cambiarla:** un administrador se la restableció y el directorio exige cambiarla (`pwdReset`).
- **Ya ha caducado:** ha superado la caducidad definida en `pwdMaxAge`.
- **Está a punto de caducar:** se encuentra dentro del periodo de aviso de `pwdExpireWarning`.

El aviso se muestra en cada inicio de sesión mientras se cumpla alguno de esos motivos, y sólo en sesiones gráficas: en una consola de texto no hay navegador que abrir.

**El usuario sabe por qué se le pide:** el agente añade el motivo a la dirección, de forma que la página de cambio de contraseña se abre ya en el formulario, con el usuario relleno y con un aviso que explica la situación en lenguaje llano («Un administrador ha restablecido tu contraseña…», «Tu contraseña caduca dentro de 5 días…»).

**Auditoría:** cada vez que se abre el navegador a un usuario queda registrado en el módulo de Auditoría, indicando el equipo y el motivo. También se registran los intentos fallidos, por ejemplo si el escritorio todavía no estaba listo o el equipo no tiene Chrome instalado.

Se configura desde `agent_config.json`:

| Opción | Valor por defecto | Descripción |
| --- | --- | --- |
| `password_prompt_enabled` | `false` | Activa el aviso. **Viene desactivado**: hay que habilitarlo expresamente en los equipos donde se quiera. |
| `password_prompt_url` | `https://educontrol.santaeulalia/change-password` | Dirección que se abre en el navegador. |
| `password_prompt_delay` | `15` | Segundos de espera desde el inicio de sesión antes de abrir el navegador, para dar tiempo a que termine de arrancar el escritorio. |
| `password_prompt_reasons` | los tres a `true` | Permite elegir qué motivos abren el navegador: `must_change`, `expired` y `expiring_soon`. Indicar sólo uno no desactiva los demás; para desactivar un motivo hay que ponerlo a `false` expresamente. |

Por ejemplo, para avisar sólo cuando la contraseña ya sea inservible, sin molestar a quien todavía tiene margen:

```json
"password_prompt_reasons": {
  "must_change": true,
  "expired": true,
  "expiring_soon": false
}
```

[Volver](../README.md)
