# Módulo de Inventario

El sistema de inventario de EduControl está diseñado para mantener un registro preciso y actualizado de todo el parque informático de forma totalmente automatizada, minimizando la carga administrativa.

## Autoinventariado Dinámico

La gestión del inventario se basa en un proceso de comunicación constante entre los agentes y el servidor central:

### 1. Sincronización al Inicio
Cada vez que un equipo cliente se inicia, el agente local se comunica automáticamente con el servidor de EduControl para realizar un **autoinventariado**. Este proceso recopila información técnica detallada del hardware y la configuración actual del sistema.

### 2. Actualización Inteligente de Datos
El sistema es capaz de detectar si un equipo ya ha sido registrado previamente en la base de datos:
- **Si el equipo es nuevo:** Se crea una nueva ficha de inventario con todos sus detalles.
- **Si el equipo ya existe:** El servidor compara los datos recibidos con los almacenados. Si se detecta cualquier cambio (como una ampliación de memoria RAM, cambio de disco duro o actualización del sistema), la información se **actualiza automáticamente** para reflejar el estado real del equipo en ese preciso instante.

## Base de Datos de Fabricantes

Además de los equipos individuales, EduControl gestiona de forma inteligente una base de datos global de fabricantes:

- **Marcas y Modelos:** Durante el proceso de autoinventariado, el sistema extrae la información de marca y modelo de cada componente y equipo.
- **Normalización Automática:** Si el agente reporta un fabricante o modelo que no existía previamente en los registros globales, el sistema lo **autoinventaría** automáticamente en la base de datos de fabricantes, permitiendo una clasificación y filtrado profesional de todos los recursos del centro.
