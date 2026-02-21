# Módulo de Integración LDAP

El módulo LDAP de EduControl permite la gestión centralizada de los servicios de directorio, facilitando la administración de identidades y recursos de red.

## Gestión de Operaciones (CRUD)

Desde la interfaz de EduControl, el administrador puede realizar operaciones completas de creación, lectura, actualización y borrado (CRUD) sobre los siguientes objetos del directorio:

### 1. Usuarios
Gestión integral de las cuentas de usuario de la organización. Permite administrar de forma centralizada quién tiene acceso a los sistemas, así como sus datos personales y credenciales.

### 2. Dispositivos
Administración de los objetos de equipo registrados en el directorio. Esta gestión es clave para que el sistema de autorenombrado de los agentes funcione correctamente.

- **Soporte Multired:** Permite registrar equipos asignando IPs tanto de la **red troncal** del centro como de la numeración IP de la **red WiFi Educarex**.
- **Gestión Inteligente de IPs:** Si al intentar registrar un nuevo equipo la dirección IP solicitada ya se encuentra ocupada, EduControl **recomienda automáticamente una IP alternativa** que esté libre, evitando conflictos de red.

### 3. Grupos de Red
Gestión de los grupos de red.

### 4. Grupos
Administración de grupos lógicos de usuarios. Permite organizar de forma funcional a los miembros del centro educativo: profesores, alumnos y personal no docente.

[Volver](../README.md)
