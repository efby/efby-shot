# Registro de cambios

## Sin publicar — identidad de la app en desarrollo

- La compilación local usa la firma Developer ID de EFBY cuando está disponible, igual que el release. Así macOS puede reconocer la app después de recompilarla y conservar su permiso de pantalla.
- **Permiso de captura…** solicita primero el permiso con el diálogo nativo y explica cuándo Ajustes del Sistema exige un administrador.

## 0.3.0 — pasos numerados y release por PR fusionado

- El editor coloca marcadores circulares 1, 2, 3… con el color seleccionado, permite deshacer y conserva los marcadores en el PNG exportado.
- Al fusionar un PR de este repositorio en `main`, GitHub compila, firma y notariza un DMG, calcula la siguiente versión y publica un GitHub Release con su etiqueta y suma SHA-256.

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
