# Registro de cambios

## 14 de octubre de 2026 — revisión de EFbyShot

Cambios observados respecto de la primera versión del repositorio (`092cee3`):

- La aplicación pasó a llamarse **EFBY Monitor Shot**, con identificador `com.efby.monitorshot`, icono EFBY y acceso permanente desde la barra de menús.
- El menú muestra los atajos globales ⇧⌘1, ⇧⌘2 y ⇧⌘0 y agrega **Permiso de captura…**.
- Se incorporó una guía para registrar la app en los permisos de grabación de pantalla de macOS y detectar rechazos de ScreenCaptureKit.
- El editor y Preferencias conservan sus ventanas mientras la app continúa en la barra; se mejoró el ciclo de cierre de ambas.
- La selección de área pasó a un panel que cubre el escritorio virtual, alinea el rectángulo a píxeles y convierte coordenadas de Cocoa a ScreenCaptureKit.
- La captura prepara el tamaño en puntos del editor a partir de la escala de la pantalla. El flujo sigue permitiendo pixelar, escribir notas, guardar, copiar, finalizar o descartar.
- La compilación local genera `dist/EFBY Monitor Shot.app` con firma ad hoc. Se añadieron scripts opcionales para firma Developer ID, notarización y empaquetado de distribución.

La compilación y la prueba automatizada del editor pasaron durante esta revisión. La firma Developer ID, la notarización y las capturas interactivas de ChatGPT y de varios monitores requieren verificación aparte; consulta `docs/REVISION-2026-10-14.md`.
