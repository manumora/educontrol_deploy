# Política de Contraseñas

EduControl gestiona desde la propia interfaz la **política de contraseñas del directorio**, que es la que impone a los usuarios los requisitos de longitud, caducidad, historial y bloqueo por intentos fallidos.

Existe una política independiente por cada colectivo, cada una con su propia entrada `pwdPolicy` del directorio:

| Colectivo | Entrada `pwdPolicy` |
| --- | --- |
| Profesores | `cn=ppteachers,ou=policies,dc=instituto,dc=extremadura,dc=es` |
| Alumnos | `cn=ppstudents,ou=policies,dc=instituto,dc=extremadura,dc=es` |
| Personal no docente | `cn=ppstaff,ou=policies,dc=instituto,dc=extremadura,dc=es` |
| Por defecto | `cn=default,ou=policies,dc=instituto,dc=extremadura,dc=es` |

Es el *overlay* **ppolicy** de OpenLDAP quien la aplica realmente: EduControl se limita a crearla, editarla y asignarla a los usuarios mediante el atributo `pwdPolicySubentry` de cada cuenta.

La política **Por defecto** es distinta a las otras tres: no se asigna a ningún usuario mediante `pwdPolicySubentry`. Es la que el overlay usa automáticamente, a través del parámetro `olcPPolicyDefault` de su configuración, para cualquier cuenta que no tenga ninguna política propia asignada — de modo que ninguna cuenta se quede sin política real por accidente, en lugar de quedar sin ningún tipo de control.

Se accede desde *LDAP* → *Usuarios*, botón **Políticas**, en la barra superior. Una vez instaladas, un desplegable **Colectivo** en la parte superior del diálogo (Profesores, Alumnos, Personal no docente o Por defecto; Profesores por defecto) determina sobre qué política se está consultando o editando en cada momento. Antes de instalar no hay nada entre lo que elegir —las cuatro se instalan a la vez—, así que el desplegable no se muestra.

## 1. Instalación

Si ninguna de las políticas existe todavía en el directorio, el diálogo no muestra ni el desplegable de colectivo ni el formulario: únicamente informa de que las políticas **no están instaladas** y advierte de que, mientras siga así, no se aplica ninguna restricción de complejidad, caducidad ni bloqueo a ningún usuario.

![Política de contraseñas no instalada](./img/instalar_politicas.png)

El botón **Instalar políticas** crea de una vez las **cuatro** políticas del centro, si todavía no existieran. Por cada una:

1. Crea la rama `ou=policies` si todavía no existiera.
2. Crea el objeto `pwdPolicy` con sus valores por defecto (los de la tabla siguiente para Profesores; sin ninguna restricción para Alumnos, Personal no docente y Por defecto, ver más abajo).
3. **Aplica la política a todos los usuarios de ese colectivo** e informa de a cuántos se les ha asignado — excepto la de **Por defecto**, que no se aplica a nadie explícitamente, tal y como se explica arriba.

Si alguna de las cuatro ya estaba instalada, se deja tal cual: no es un error, simplemente se instalan las que faltaban.

Crear las políticas es prácticamente instantáneo, pero aplicarlas a los usuarios puede tardar más, dependiendo de cuántos tenga el centro. Al terminar, un resumen muestra por separado cuántos profesores, alumnos y personal no docente han recibido la política, cuántos ya la tenían y cuántos han fallado.

> ⚠️ **Importante**: tras instalar las políticas queda un único paso más, y hay que darlo como root en el propio servidor LDAP para que las políticas empiecen a funcionar de verdad:
>
> ```
> ldapmodify -Y EXTERNAL -H ldapi:/// -f ppolicy-overlay.ldif
> ```
>
> El fichero [`ppolicy-overlay.ldif`](./assets/ppolicy-overlay.ldif) está listo para usarse tal cual.

Los valores por defecto con los que se crea la política de **Profesores** son:

| Atributo | Valor | Significado |
| --- | --- | --- |
| `pwdAttribute` | `userPassword` | Atributo sobre el que se aplica la política |
| `pwdCheckQuality` | `2` | Comprueba siempre la calidad y rechaza la contraseña si no puede comprobarla |
| `pwdMinLength` | `8` | Longitud mínima en caracteres |
| `pwdInHistory` | `5` | Contraseñas anteriores que no se pueden reutilizar |
| `pwdMaxAge` | `15552000` | Caduca a los 180 días |
| `pwdMinAge` | `0` | Sin espera para volver a cambiarla |
| `pwdExpireWarning` | `864000` | Avisa al usuario 10 días antes de que caduque |
| `pwdMaxIdle` | `31104000` | Bloquea la cuenta tras 360 días sin uso |
| `pwdGraceAuthNLimit` | `1` | Un único acceso de gracia con la contraseña caducada |
| `pwdLockout` | `TRUE` | Bloquea la cuenta al superar los intentos fallidos |
| `pwdMaxFailure` | `3` | Fallos consecutivos antes de bloquear |
| `pwdLockoutDuration` | `900` | El bloqueo dura 15 minutos |
| `pwdFailureCountInterval` | `900` | Los fallos se olvidan a los 15 minutos |
| `pwdAllowUserChange` | `TRUE` | El usuario puede cambiar su propia contraseña |
| `pwdMustChange` | `TRUE` | Obliga a cambiarla en el primer acceso tras un restablecimiento |
| `pwdSafeModify` | `TRUE` | Exige la contraseña actual para poder cambiarla |

Las políticas de **Alumnos**, **Personal no docente** y **Por defecto** se crean en cambio sin ninguna restricción: comprobación de calidad desactivada, sin longitud mínima, sin historial, sin caducidad y sin bloqueo por intentos fallidos (todos los valores numéricos a `0` y los interruptores `pwdLockout`, `pwdMustChange` y `pwdSafeModify` a `FALSE`; `pwdAllowUserChange` se deja en `TRUE` para que el usuario pueda seguir cambiando su propia contraseña). Sirven como punto de partida neutro: se pueden editar después igual que la de Profesores en cuanto el centro quiera empezar a exigir algo a esas cuentas.

## 2. Edición

Una vez instalada, el diálogo muestra el formulario con la configuración vigente del colectivo seleccionado en el desplegable, agrupada en cinco bloques: general, complejidad e historial, caducidad, bloqueo por intentos fallidos y comportamiento del usuario.

![Edición de la política de contraseñas](./img/editar_politicas.png)

Todos los valores son editables y se guardan directamente en el directorio. Los campos expresados en segundos, tal y como los almacena LDAP, muestran debajo su equivalencia en días, horas y minutos para no tener que calcularla a mano.

Cada modificación queda registrada en el módulo de Auditoría con el detalle de los atributos que han cambiado.

Los cambios se aplican al momento a todos los usuarios del colectivo seleccionado que ya tengan su política asignada: no hace falta volver a aplicarla.

## 3. Aplicación a un colectivo

Que cada cuenta apunte a su política no requiere una acción manual aparte en el uso normal: al instalar las políticas (paso 1) ya se aplican de inmediato a todos los usuarios del colectivo correspondiente, y desde ese momento cualquier alta o cambio de tipo —ya sea a mano desde *Usuarios*, o mediante la importación de profesores o alumnos— asigna la política adecuada automáticamente, sin ninguna opción para desactivarlo.

El botón **Aplicar políticas** existe para los casos en los que una cuenta se haya quedado sin la política que le corresponde —por ejemplo, si se instaló la política después de dar de alta a algunos usuarios de otra forma, o tras un fallo puntual—: recorre el directorio y asigna la política del colectivo seleccionado en el desplegable a **todos sus usuarios**, entendiendo por tales los usuarios cuyo directorio personal cuelga de `/home/profesor`, `/home/alumnos` o `/home/staff` según corresponda — el mismo criterio con el que la plataforma calcula el tipo de usuario. Con **Por defecto** seleccionada no aparece este botón: esa política no se asigna a ningún colectivo, es el propio overlay quien la usa automáticamente (ver [Instalación](#1-instalación)).

Al terminar informa de a cuántos usuarios se ha aplicado, cuántos ya la tenían y cuántos han fallado, con el detalle de los errores en su caso. Los usuarios que ya la tenían asignada no se modifican, así que es una operación segura de repetir cuantas veces se quiera, aunque no haga falta.

## 4. Estado de la cuenta de un usuario

Desde el listado de usuarios, el icono de **historial de contraseñas** de cada fila abre el detalle de esa cuenta: la fecha del último cambio, las contraseñas anteriores registradas por el directorio y, sobre todo, **el estado que impone la política**.

![Historial de contraseñas de un usuario](./img/usuario_historial_passwords.png)

El panel de estado responde a las preguntas del día a día:

- Si la cuenta está **bloqueada**, desde cuándo y si se desbloqueará sola o el bloqueo es indefinido.
- Cuántas veces se ha **fallado la contraseña** y cuántos intentos quedan antes del bloqueo. Sólo se cuentan los fallos vigentes: los anteriores al intervalo de recuento ya han caducado.
- Cuándo **caduca la contraseña** y cuánto falta, o si no caduca nunca.
- Si el usuario **debe cambiarla** por habérsela restablecido un administrador.
- El **último acceso correcto**, los **accesos de gracia** consumidos, desde cuándo puede volver a cambiarla y las fechas de creación y última modificación de la cuenta.

Cuando la cuenta está bloqueada aparece el botón **Desbloquear**, que borra el bloqueo y el contador de intentos fallidos sin esperar a que venza el plazo. La operación queda registrada en el módulo de Auditoría.

La pantalla avisa además cuando el usuario **no tiene la política asignada** —y permite aplicársela individualmente— o cuando la política no existe todavía en el directorio.

> El estado se obtiene de los atributos operativos que mantiene el overlay ppolicy. Si el directorio no los devuelve (porque las ACL no lo permiten, o porque el usuario no ha cambiado nunca su contraseña), el panel lo indica expresamente en lugar de dar la cuenta por correcta.

## 5. Avisos en el listado

Las filas del listado de usuarios muestran un icono de aviso cuando la cuenta necesita atención: **candado rojo** si está bloqueada, **triángulo ámbar** si la contraseña caduca pronto o ya ha caducado, y un icono azul si el usuario debe cambiarla. Al pulsarlo se abre el detalle de esa cuenta.

Estos avisos se consultan aparte del listado, de modo que la tabla se muestra igual de rápido que antes y los iconos aparecen un instante después.

[Volver](../README.md)
