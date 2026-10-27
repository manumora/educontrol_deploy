# Cartelería digital

EduControl decide qué webs se ven en las TV del centro (sala de profesores, conserjería…) a lo largo del día. Cada TV es una **pantalla** con su propia programación y su propio **reproductor**, una página de EduControl que abre en modo kiosk el equipo conectado a esa TV (por ejemplo, una Raspberry Pi 5 con Chromium). De cada pantalla se configuran dos pistas:

- **Rotación**: una playlist de webs que se repite en bucle, cada una con sus segundos en pantalla.
- **Fijaciones**: bloques horarios en los que una única web se queda fija (recreos, cambios de guardia…). Tienen prioridad sobre la rotación.

Los cambios llegan a la TV en unos segundos, sin reiniciar la Raspberry ni recargar el navegador.

## Uso desde EduControl

Todo está en el menú **Cartelería**:

| Página | Para qué |
|---|---|
| *Webs* | Catálogo de webs: nombre, URL, duración por defecto, auto-refresco y color en la línea de tiempo. El botón **Comprobar** avisa si la web prohíbe mostrarse dentro de un iframe o si es `http://`. |
| *Pantallas* | Alta, edición y baja de pantallas: nombre, ubicación, jornada, comportamiento fuera de ella, equipos en modo kiosk, estado de la TV y URL del reproductor. |
| *Programación* | Playlist de rotación (ordenable arrastrando) y línea de tiempo de la jornada de la pantalla elegida en el desplegable. |

El catálogo de webs es común: una misma web puede estar en la playlist o en los bloques de varias pantallas. Cada pantalla tiene su playlist, sus bloques fijos y su URL de reproductor; al eliminar una pantalla se borra su programación y sus equipos kiosk cierran el navegador.

### Programación

- **Pantalla**: elígela en el desplegable de la cabecera. El editor recuerda la última que abriste; desde *Pantallas* también se llega con el botón de programación de cada fila. Si cambias de pantalla con cambios sin guardar, pide confirmación.
- **Playlist**: arrastra las webs por el asa para ordenarlas. Si dejas vacío el campo de segundos se usa la duración por defecto de la web.
- **Línea de tiempo**: elige el día de la semana arriba a la derecha. En la pista *Fijaciones*:
  - arrastra sobre un hueco para crear un bloque (o haz clic para crear uno de 30 minutos);
  - arrastra un bloque para moverlo y tira de sus bordes para cambiar la duración (rejilla de 5 minutos);
  - haz clic en un bloque para cambiar la web, los días, el auto-refresco o la etiqueta, o para eliminarlo.
- Dos bloques de la misma pantalla no pueden solaparse en ningún día que compartan. El editor lo marca en rojo y el servidor rechaza el guardado.
- Nada se aplica hasta pulsar **Guardar**. La tarjeta superior muestra qué se vería ahora con la programación del editor y cuál es el siguiente cambio.

### Auto-refresco

Una web fija con auto-refresco (por ejemplo, el cuadrante de guardias cada 5 minutos) se vuelve a cargar en segundo plano y se cambia cuando ha terminado de cargar, sin parpadeo. El valor del bloque tiene prioridad sobre el de la web. En la rotación no hace falta: cada vez que una web vuelve a salir se carga de nuevo.

### Fuera de jornada

En cada pantalla (*Pantallas*) se elige si fuera de la jornada la TV se queda en negro (los dos iframes se vacían) o sigue rotando. Los bloques fijos se muestran aunque estén fuera de la jornada.

## Cómo funciona el reproductor

El reproductor (`/signage/player/<token>`) es una página independiente de unos 12 KB, sin React, pensada para estar encendida 24/7:

- **Doble buffer**: solo existen dos iframes. La siguiente web se carga en el oculto unos segundos antes del cambio (8 por defecto, *Pre-carga*), se intercambian las opacidades con un fundido de 0,4 s y el que queda oculto vuelve a `about:blank` para liberar memoria. Si la siguiente web aún no ha cargado, se mantiene la actual: nunca se ve un blanco.
- **Horario**: un reloj interno revisa cada segundo la franja actual con la hora del servidor (zona horaria y desfase corregidos), así que no depende de que la Raspberry tenga bien la hora.
- **Sin red**: guarda la última programación en `localStorage` y sigue funcionando si se cae la conexión con EduControl. Antes de cargar cada web comprueba que es alcanzable. Si no lo es, en la rotación salta a la siguiente; si es una web fija, o fallan todas, muestra un overlay con la hora y la fecha en lugar de la página de error de Chromium, y lo reintenta cada 30 segundos.
- **Sincronización**: recibe los cambios por WebSocket (`/ws/signage/<token>/`) y, si el WebSocket cae, consulta la versión de la programación cada 30 segundos. Cada minuto envía un latido que se ve en *Cartelería → Pantallas*.
- **Mantenimiento**: a las 04:00, si no hay un bloque fijo y el servidor responde, se recarga para soltar cualquier fuga de memoria de Chromium.

### Limitaciones

- **Webs que prohíben los iframes** (cabeceras `X-Frame-Options` o CSP `frame-ancestors`, habituales en Google, redes sociales y muchos portales): no se ven en ningún navegador normal. En los equipos en modo kiosk, el agente carga en el navegador una extensión que quita esas cabeceras **solo** a los documentos cargados en iframes. Es aceptable porque el navegador del kiosk no lo usa nadie más. Funciona con Chromium; Google Chrome 137 o posterior ignora las extensiones cargadas así, por eso el agente prefiere Chromium.
- **Webs `http://`**: EduControl se sirve por HTTPS y Chromium bloquea el contenido mixto. Usa la versión `https://` de la web o activa *Permitir webs http://* en la pantalla (*Cartelería → Pantallas*).
- **Errores dentro de la web**: el reproductor detecta webs inalcanzables (DNS, conexión rechazada, certificado, sin red) y webs que no terminan de cargar. Una web que responde con su propia página de error (un 404, por ejemplo) se muestra tal cual, porque el contenido de otro dominio no es accesible desde el reproductor.

## Equipos en modo kiosk

El reproductor de una pantalla se abre solo en los equipos que elijas en su ficha (*Cartelería → Pantallas*, sección *Equipos en modo kiosk*). Un equipo solo puede mostrar una pantalla: los que ya están en otra aparecen desactivados en la lista. No hace falta ejecutar nada en el equipo: lo hace el agente de EduControl.

Requisitos del equipo (por ejemplo, una Raspberry Pi 5 con Raspberry Pi OS Bookworm):

- el **agente de EduControl** instalado y conectado;
- **Chromium** (o Google Chrome) instalado;
- **inicio de sesión automático** en el escritorio, para que tras un reinicio haya una sesión en la que abrir el navegador (en Raspberry Pi OS: `sudo raspi-config nonint do_boot_behaviour B4`).

Al pulsar **Guardar**, EduControl envía a los agentes conectados la URL del reproductor (los desconectados la reciben al conectarse). Desde ese momento el agente:

- guarda la URL en `/etc/educontrol/kiosk-state.json`, de modo que tras un reinicio vuelve a abrir el kiosk aunque EduControl no responda;
- cada 10 segundos comprueba que el navegador está abierto en la sesión gráfica de la consola (VT 7) y, si no lo está, lo abre. Así se recupera si alguien lo cierra, si se cuelga o tras cerrar y abrir sesión;
- lanza el navegador como unidad de systemd propia, `educontrol-kiosk`, con el usuario de la sesión y un perfil aparte (`~/.config/educontrol-kiosk`). Por eso sigue abierto aunque se reinicie o se actualice el agente;
- usa Chromium si está instalado y, si no, Google Chrome, con `--kiosk` y las opciones para que no aparezcan avisos (restaurar sesión, traducir, primer arranque…);
- mantiene la pantalla encendida (`xset` en X11; en Wayland de Raspberry Pi OS, `raspi-config nonint do_blanking 1`).

Si quitas un equipo de la lista, el agente cierra el navegador.

En el propio equipo se puede consultar con `systemctl status educontrol-kiosk` y `journalctl -u educontrol-kiosk`.

Opciones de la misma tarjeta:

| Opción | Para qué |
|---|---|
| URL pública de EduControl | Dirección con la que los equipos llegan a EduControl. Si se deja vacía, se guarda la del navegador del administrador. |
| Ignorar errores de certificado | Necesario si EduControl usa un certificado autofirmado (activado por defecto). |
| Permitir webs http:// | Permite contenido mixto dentro del reproductor. |

Si varios equipos muestran la misma pantalla (dos TV con el mismo contenido), el estado «TV conectada» de esa pantalla refleja el último latido recibido de cualquiera de ellos.

### Regenerar el token

Quien tenga la URL del reproductor puede ver la programación (no puede cambiarla). Si se ha difundido, pulsa **Regenerar token** en la ficha de la pantalla: sus equipos en modo kiosk reciben la URL nueva automáticamente. Cualquier otro navegador con la URL antigua sigue mostrando la última programación que recibió.

## API

| Método | Ruta | Acceso |
|---|---|---|
| `GET`, `POST` | `/api/signage/sites/` | Sesión |
| `PUT`, `DELETE` | `/api/signage/sites/<id>/` | Sesión |
| `POST` | `/api/signage/sites/check/` | Sesión |
| `GET`, `POST` | `/api/signage/screens/` | Sesión |
| `GET`, `PUT`, `DELETE` | `/api/signage/screens/<id>/` | Sesión |
| `POST` | `/api/signage/screens/<id>/regenerate-token/` | Sesión |
| `GET` | `/api/signage/kiosk/computers/` (equipos con agente para el modo kiosk) | Sesión |
| `GET`, `PUT` | `/api/signage/screens/<id>/schedule/` (playlist y bloques de la pantalla en una sola transacción) | Sesión |
| `GET` | `/api/signage/player/<token>/config` y `/version` | Token |
| `POST` | `/api/signage/player/<token>/heartbeat` | Token |
| WebSocket | `/ws/signage/<token>/` | Token |
