# MonitorShot

App nativa de macOS que corre en la cuenta del usuario estándar. No requiere `sudo`, instalador, cuenta de servicio ni dependencias de terceros en tiempo de ejecución.

## Requisitos

- macOS 26 o posterior, Apple Silicon.
- Permiso del usuario para «Grabación de pantalla y audio del sistema».
- Xcode 27 solo para compilar el código fuente.

## Uso

Abre `MonitorShot.app` desde `dist/` o cualquier carpeta; no hace falta instalarla en Aplicaciones. La aplicación despliega su menú en la barra superior al iniciarse o cuando vuelves a abrirla. Después puedes pulsar el icono EFBY Shot para desplegarlo otra vez. El acceso permanece allí incluso cuando cierras el editor o Preferencias. En pantallas con cámara central, la app ajusta el espacio de su icono para colocarlo en una zona visible de la barra; cuando hay lugar junto a los demás iconos, retira esa reserva. Desde el menú puedes capturar un área, una ventana o un monitor y abrir Preferencias. También puedes capturar con ⇧⌘1, ⇧⌘2 y ⇧⌘0, respectivamente. La opción **Salir de MonitorShot** termina el proceso.

Si macOS rechaza una captura, menú **Permiso de captura…** y en Ajustes activa la misma copia de `MonitorShot.app` que ejecutas (botón + si no está en la lista). Cierra la app y ábrela otra vez desde esa carpeta.

En el editor puedes añadir flechas, rectángulos, óvalos y resaltados. Con **Pixelar**, arrastra sobre el texto que quieras ofuscar. Con **Texto**, haz clic en la propia imagen, escribe la nota y pulsa Intro. También puedes deshacer, guardar como PNG o copiar la imagen al portapapeles. **Descartar** cierra la captura sin guardar ni copiar. Si activas destinos en Preferencias, se aplican solamente al pulsar **Finalizar**; elegir Descartar no produce archivos ni cambia el portapapeles. También puedes elegir una carpeta y solicitar que la app arranque al iniciar la sesión.

## Compilar

### Desarrollo local (firma ad hoc)

`zsh build.sh` → `dist/MonitorShot.app` con firma `-` para probar en tu Mac. Cada build cambia el hash y puede obligarte a reactivar el permiso de captura en Ajustes.

### Release EFBY (Developer ID + notarización)

Requiere en el llavero la identidad **Developer ID Application: EFBY SERVICIOS INFORMATICOS LIMITADA (FYU5QTGXLB)** y un perfil de `notarytool` (una sola vez):

```zsh
xcrun notarytool store-credentials "EFBY-Notary" \
  --apple-id "tu-correo@efby.cl" --team-id FYU5QTGXLB
export MONITORSHOT_NOTARY_PROFILE=EFBY-Notary
zsh release.sh
```

Salidas en `dist/`:

- `MonitorShot.app` — firmada con Developer ID, grapada (stapled)
- `MonitorShot-macOS26.dmg` — DMG notarizado
- `MonitorShot-macOS26.zip` — zip de la app para distribución

Solo compilar y firmar sin enviar a Apple: `zsh release.sh --skip-notarize`

Variables opcionales: `MONITORSHOT_SIGN_IDENTITY`, `MONITORSHOT_NOTARY_PROFILE`.

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
