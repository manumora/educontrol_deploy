# EduControl

EduControl es una plataforma integral diseñada para la gestión, monitorización y control de equipamiento tecnológico, orientada a entornos educativos. Permite administrar de forma centralizada los dispositivos, visualizar su ubicación a través de mapas, gestionar usuarios y obtener métricas de uso.

## Módulos Principales del Proyecto

El sistema se estructura en varios módulos fundamentales. A continuación se incluye una breve explicación de cada uno, junto con los enlaces a su correspondiente documentación:

- **[Agentes](./docs/AGENTS.md)**: Encargados de la recolección de datos y la monitorización constante de los equipos cliente en tiempo real.
- **[Inventario](./docs/INVENTORY.md)**: Gestión del hardware, características y software de todos los dispositivos registrados en la red.
- **[LDAP](./docs/LDAP.md)**: Módulo de integración con el servidor LDAP para la gestión de usuarios y dispositivos.
- **[Mapas](./docs/MAPS.md)**: Interfaz para la representación visual y localización física de los equipos sobre los planos del centro educativo.
- **[Documentos](./docs/REPORTS.md)**: Herramienta para la generación de documentos.

## Instalación del Servidor EduControl

Para conocer todos los detalles sobre cómo instalar, configurar y actualizar el servidor EduControl, consulta la [Instalación del Servidor](./docs/INSTALLATION.md).

---

## Instalación del Agente Puppet

Para instalar el agente EduControl en los clientes mediante Puppet, consulta la documentación en [`Instalación del Agente`](agent/README.md).
