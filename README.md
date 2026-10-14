# MonitorShot

App nativa de macOS que corre en la cuenta del usuario estándar. No requiere `sudo`, instalador, cuenta de servicio ni dependencias de terceros en tiempo de ejecución.

## Requisitos

- macOS 26 o posterior, Apple Silicon.
- Permiso del usuario para «Grabación de pantalla y audio del sistema».
- Xcode 27 solo para compilar el código fuente.

## Uso

Abre `MonitorShot.app`. La aplicación despliega su menú en la barra superior al iniciarse o cuando vuelves a abrirla. Después puedes pulsar el icono EFBY Shot para desplegarlo otra vez. El acceso permanece allí incluso cuando cierras el editor o Preferencias. En pantallas con cámara central, la app ajusta el espacio de su icono para colocarlo en una zona visible de la barra; cuando hay lugar junto a los demás iconos, retira esa reserva. Desde el menú puedes capturar un área, una ventana o un monitor y abrir Preferencias. También puedes capturar con ⇧⌘1, ⇧⌘2 y ⇧⌘0, respectivamente. La opción **Salir de MonitorShot** termina el proceso.

Si macOS rechaza una captura, activa MonitorShot en Ajustes del Sistema > Privacidad y seguridad > Grabación de pantalla y audio del sistema, cierra la app y ábrela otra vez.

En el editor puedes añadir flechas, rectángulos, óvalos y resaltados. Con **Pixelar**, arrastra sobre el texto que quieras ofuscar. Con **Texto**, haz clic en la propia imagen, escribe la nota y pulsa Intro. También puedes deshacer, guardar como PNG o copiar la imagen al portapapeles. **Descartar** cierra la captura sin guardar ni copiar. Si activas destinos en Preferencias, se aplican solamente al pulsar **Finalizar**; elegir Descartar no produce archivos ni cambia el portapapeles. También puedes elegir una carpeta y solicitar que la app arranque al iniciar la sesión.

## Compilar

Desde esta carpeta: `zsh build.sh`. El proceso genera el logo EFBY de la app desde el recurso vectorial, produce `AppIcon.icns`, compila en una carpeta temporal y reemplaza el paquete solo tras firmarlo y verificarlo. El resultado se escribe en `dist/MonitorShot.app`. En `dist/MonitorShot-macOS26.zip` está la aplicación ya empaquetada. El paquete lleva firma local ad hoc para esta prueba. Para distribuirlo a otros equipos sin advertencias de Gatekeeper, el desarrollador debe firmarlo y notarizarlo; el usuario final no necesita credenciales para usarlo.

## Estructura

- `Domain/`: modos, ajustes y errores.
- `Application/`: coordinación de los casos de uso.
- `Infrastructure/`: ScreenCaptureKit, preferencias, PNG y portapapeles.
- `Presentation/`: ventanas, selección de área y editor.
- `App/`: arranque, barra de menús y atajos globales.
- `Resources/`, `Tools/` y `scripts/`: recurso vectorial EFBY, generación del icono y empaquetado de la app.

## Alcance de esta versión

La captura de monitor permite elegir uno a la vez. Los atajos se muestran en Preferencias, pero aún no se pueden cambiar allí. El permiso de captura debe concederse por el usuario en macOS; no puede otorgarlo la aplicación.
