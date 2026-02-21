# Módulo de Agentes

El módulo de Agentes de EduControl es la pieza fundamental para la comunicación y administración remota de los dispositivos de la red. Cada equipo cliente ejecuta un agente en segundo plano que permite realizar tareas avanzadas de gestión de forma centralizada.

## Funcionalidades Principales

### 1. Terminal Remota
A través del agente, el administrador puede abrir una sesión de terminal interactiva directamente contra el equipo remoto. Esto permite la ejecución de comandos en tiempo real, facilitando la resolución de problemas y la configuración del sistema operativo sin necesidad de desplazarse físicamente.

### 2. Administración Gráfica (VNC)
Para aquellos casos en los que se requiera interacción visual, el agente integra la posibilidad de iniciar una sesión VNC (Virtual Network Computing). Con este acceso remoto completo al escritorio, el administrador puede operar el equipo como si estuviera frente a él, brindando soporte directamente a los usuarios o configurando aplicaciones con interfaz gráfica.

### 3. Ejecución Simultánea de Comandos
EduControl permite la ejecución masiva de comandos u operaciones en múltiples agentes **simultáneamente**. Puedes seleccionar varios equipos a la vez y lanzar tareas administrativas sobre todos ellos, lo que reduce dramáticamente los tiempos de mantenimiento para laboratorios o aulas completas.

### 4. Sistema de Autorenombrado (Integración LDAP)
El agente posee una característica inteligente de autorenombrado. Durante su inicio, el agente consulta si el equipo está registrado en el servicio de directorio (LDAP) de la organización. 

- Si el equipo es encontrado en LDAP, el agente extrae el nombre de host (*hostname*) asignado oficialmente en el directorio.
- A continuación, se **autorenombra** el equipo de manera transparente para reflejar exactamente el identificador oficial de LDAP. Además dicho nombre se actualiza en el inventario de EduControl manteniendo el inventario organizado automáticamente sin intervención manual.

[Volver](../README.md)
