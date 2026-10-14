# MonitorShot

App nativa de macOS que corre en la cuenta del usuario estándar. No requiere `sudo`, instalador, cuenta de servicio ni dependencias de terceros en tiempo de ejecución.

## Requisitos

- macOS 26 o posterior, Apple Silicon.
- Permiso del usuario para «Grabación de pantalla y audio del sistema».
- Xcode 27 solo para compilar el código fuente.

## Uso

Abre `dist/EFBY Monitor Shot.app` o cópiala a una carpeta de tu usuario; no hace falta instalarla en Aplicaciones. La aplicación despliega su menú en la barra superior al iniciarse o cuando vuelves a abrirla. Después puedes pulsar el icono EFBY Shot para desplegarlo otra vez. El acceso permanece allí incluso cuando cierras el editor o Preferencias. En pantallas con cámara central, la app ajusta el espacio de su icono para colocarlo en una zona visible de la barra; cuando hay lugar junto a los demás iconos, retira esa reserva. Desde el menú puedes capturar un área, una ventana o un monitor y abrir Preferencias. También puedes capturar con ⇧⌘1, ⇧⌘2 y ⇧⌘0, respectivamente. La opción **Salir de MonitorShot** termina el proceso.

Si macOS rechaza una captura o solo muestra el fondo de pantalla, usa **Permiso de captura…**. En Ajustes del Sistema > Privacidad y seguridad > Grabación de pantalla y audio del sistema, activa la misma copia de `EFBY Monitor Shot.app` que ejecutas (botón + si no está en la lista). Sal de la app y ábrela otra vez desde esa carpeta. La captura nativa de macOS tiene su propio permiso y no confirma que EFBY Monitor Shot lo tenga.

En el editor puedes añadir flechas, rectángulos, óvalos y resaltados. Con **Pixelar**, arrastra sobre el texto que quieras ofuscar. Con **Texto**, haz clic en la propia imagen, escribe la nota y pulsa Intro. Con **Paso**, haz clic en cada punto de la imagen para colocar 1, 2, 3…; cada nuevo círculo toma el color seleccionado. **Deshacer** quita el último y reutiliza su número en el siguiente paso. También puedes guardar como PNG o copiar la imagen al portapapeles. **Descartar** cierra la captura sin guardar ni copiar. Si activas destinos en Preferencias, se aplican solamente al pulsar **Finalizar**; elegir Descartar no produce archivos ni cambia el portapapeles. También puedes elegir una carpeta y solicitar que la app arranque al iniciar la sesión.

## Compilar

### Desarrollo local (firma ad hoc)

`zsh build.sh` → `dist/EFBY Monitor Shot.app` con firma `-` para probar en tu Mac. Cada build cambia el hash y puede obligarte a reactivar el permiso de captura en Ajustes.

### Release EFBY (Developer ID + notarización)

Requiere en el llavero la identidad **Developer ID Application: EFBY SERVICIOS INFORMATICOS LIMITADA (FYU5QTGXLB)** y un perfil de `notarytool` (una sola vez):

```zsh
xcrun notarytool store-credentials "EFBY-Notary" \
  --apple-id "tu-correo@efby.cl" --team-id FYU5QTGXLB
export MONITORSHOT_NOTARY_PROFILE=EFBY-Notary
zsh release.sh
```

Salidas en `dist/`:

- `EFBY Monitor Shot.app` — firmada con Developer ID, grapada (stapled)
- `MonitorShot-macOS26.dmg` — DMG notarizado
- `MonitorShot-macOS26.zip` — zip de la app para distribución

Solo compilar y firmar sin enviar a Apple: `zsh release.sh --skip-notarize`. Este modo no crea el DMG ni el ZIP de distribución.

Variables opcionales: `MONITORSHOT_SIGN_IDENTITY`, `MONITORSHOT_NOTARY_PROFILE`.

### Release automático en GitHub

El workflow [`.github/workflows/release.yml`](.github/workflows/release.yml) usa el mismo certificado Developer ID y los mismos nombres de secretos que EFBY Git Desk. En **Settings → Secrets and variables → Actions** del repositorio `efby/efby-shot` deben estar disponibles:

| Secreto | Contenido |
| --- | --- |
| `MACOS_CERTIFICATE_P12_BASE64` | Certificado Developer ID Application de EFBY con su clave privada, exportado como `.p12` y codificado en base64 sin saltos de línea. |
| `MACOS_CERTIFICATE_PASSWORD` | Contraseña de exportación del `.p12`. |
| `APPLE_ID` | Apple ID autorizado para notarizar con el equipo EFBY. |
| `APPLE_APP_SPECIFIC_PASSWORD` | Contraseña específica de app de ese Apple ID para `notarytool`. |
| `APPLE_TEAM_ID` | `FYU5QTGXLB`. |

Los secretos pueden ser del repositorio o de la organización si `efby/efby-shot` tiene acceso a ellos. No se guardan en el código. El workflow importa el certificado en un llavero temporal, compila con Xcode 27, firma la aplicación, pide a Apple la notarización de la app y del DMG, grapa los tickets y verifica el contenido del DMG. Al terminar elimina el llavero temporal.

Al fusionar un PR de este repositorio en `main`, GitHub genera automáticamente la siguiente versión desde `Resources/Info.plist` y las etiquetas existentes, compila y notariza el DMG y crea el tag `vX.Y.Z` con un GitHub Release. El primer release de esta función parte de `v0.3.0`; los siguientes incrementan el parche. Los PR abiertos aún no reciben secretos de firma. También puedes ejecutarlo manualmente desde **Actions → Release DMG firmado y notarizado → Run workflow** en `main` para publicar una versión, o enviar un tag `v*` con una versión concreta. El DMG, `.sha256`, ZIP y recibos de Apple quedan como artefactos de la ejecución; el DMG, `.sha256` y ZIP se adjuntan al Release.

La firma y la notarización dependen de los secretos y del servicio de Apple. El flujo de firma y notarización se verificó en GitHub Actions el 14 de octubre de 2026; cada nueva versión debe terminar correctamente para considerarse distribuible.

Identificador de paquete: `com.efby.monitorshot` (misma taxonomía que `com.efby.EfbyGitDesk`, `com.efby.meetrecorder`, etc.).

## Estructura

- `Domain/`: modos, ajustes y errores.
- `Application/`: coordinación de los casos de uso.
- `Infrastructure/`: ScreenCaptureKit, preferencias, PNG y portapapeles.
- `Presentation/`: ventanas, selección de área y editor.
- `App/`: arranque, barra de menús y atajos globales.
- `Resources/`, `Tools/` y `scripts/`: recurso vectorial EFBY, generación del icono y empaquetado de la app.

## Alcance de esta versión

La captura de monitor permite elegir uno a la vez. Los atajos se muestran en Preferencias, pero aún no se pueden cambiar allí. El permiso de captura debe concederse por el usuario en macOS; no puede otorgarlo la aplicación.

## Cambios y verificación

Consulta [CHANGELOG.md](CHANGELOG.md) para los cambios recientes y [docs/REVISION-2026-10-14.md](docs/REVISION-2026-10-14.md) para la revisión técnica, las pruebas realizadas y lo que aún requiere comprobación manual.
