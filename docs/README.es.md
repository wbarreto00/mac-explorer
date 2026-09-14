# Mac Explorer

**Gestor de archivos nativo para Apple Silicon, con organización de carpetas inspirada en Windows Explorer.**

[English](../README.md) · [Português (Brasil)](README.pt-BR.md) · Español

Árbol de carpetas, pestañas, ordenación y agrupación independientes, con una configuración guardada para cada carpeta. Desarrollado con SwiftUI y AppKit, sin dependencias externas, cuentas, anuncios ni analítica de uso.

**[Descargar Mac Explorer](https://github.com/wbarreto00/mac-explorer/releases/latest)** · [Guía de uso](USER_GUIDE.es.md) · [Informar de un problema](https://github.com/wbarreto00/mac-explorer/issues)

## Instalación

1. Utiliza un Mac con **Apple Silicon (M1 o posterior)**. Intel y Rosetta no son compatibles. El objetivo mínimo es **macOS 14**; esta versión solo se ha probado en macOS 26.6.2.
2. Descarga **Mac-Explorer-Apple-Silicon.zip** desde la [última versión](https://github.com/wbarreto00/mac-explorer/releases/latest). Los archivos “Source code” son para desarrolladores.
3. Abre el ZIP y arrastra **Mac Explorer.app** a **Aplicaciones**.
4. Abre la app y permite el acceso a las carpetas que quieras utilizar cuando macOS lo solicite.

**Firma:** esta versión utiliza una firma local, sin Apple Developer ID ni notarización. macOS puede bloquear la copia descargada. Si confías en esta versión, intenta abrirla una vez y entra en **Ajustes del Sistema → Privacidad y seguridad → Abrir igualmente**, según la [guía de Apple](https://support.apple.com/es-es/guide/mac-help/mh40616/mac). También puedes compilar el código. Es una primera versión pública; otros Macs y versiones de macOS todavía no se han verificado.

Para comprobar la integridad, descarga `SHA256SUMS.txt` en la misma carpeta que el ZIP y ejecuta `shasum -a 256 -c SHA256SUMS.txt`. Para actualizar, cierra la app y sustituye la copia en Aplicaciones. Se conservan los favoritos y la organización. Para desinstalar, mueve la app a la Papelera; no instala servicios ni elementos de inicio.

## Idioma

El idioma predeterminado es **inglés**. Abre **Mac Explorer → Settings…** (⌘,), selecciona **Español**, cierra la app y vuelve a abrirla. Después, el menú aparecerá como **Ajustes…**. También puedes elegir inglés, portugués de Brasil o **Seguir el idioma de macOS**. Esta última opción utiliza un idioma compatible de las preferencias del sistema y recurre al inglés si no hay ninguno. Las variantes de portugués utilizan la traducción brasileña. No se traducen los nombres de archivo; fechas y tamaños mantienen los formatos regionales del Mac.

## Funciones

- Árbol desplegable, favoritos, pestañas, ventanas, atrás, adelante, carpeta superior y ruta editable.
- Detalles, lista, cuatro tamaños de iconos, mosaicos, contenido, propiedades y vista previa nativa.
- Ordenación por nombre, tipo, tamaño, extensión, etiquetas y fechas de modificación, creación y adición; orden ascendente o descendente y carpetas primero.
- Agrupación independiente por nombre, tipo, tamaño, extensión, etiquetas, modificación o creación.
- Columnas seleccionables, redimensionables y reordenables; configuración por carpeta o predeterminada.
- Crear carpeta, renombrar, copiar, cortar, pegar, copiar/mover a, etiquetas, Papelera y deshacer el último movimiento.
- Búsqueda por nombre en la carpeta o subcarpetas, limitada a 10.000 resultados.
- Discos locales, extraíbles y recursos de red ya montados en macOS.

Arrastrar y soltar **copia**. Para mover, utiliza Cortar/Pegar o Mover a. Si hay un conflicto al copiar o mover, se conservan ambos elementos añadiendo un número al nombre. No hay sobrescritura automática ni fusión de carpetas. Deshacer restaura el último movimiento, cambio de nombre o envío a la Papelera de la sesión; rechaza los conflictos en la ubicación original. Las copias, carpetas nuevas y etiquetas no tienen deshacer. La búsqueda no lee el contenido de los documentos.

La app trabaja con archivos locales y volúmenes montados, sin telemetría propia, cuenta ni actualizador automático. Las carpetas en la nube y de red siguen utilizando sus respectivos proveedores. No sustituye a Finder. No incluye doble panel, extracción de archivos, cambio de nombre por lotes, conexión directa a SMB ni historial completo. Actualiza las búsquedas recursivas con ⌘R tras cambios en subcarpetas. Consulta los atajos en la [guía](USER_GUIDE.es.md).

## Compilar

En un Mac Apple Silicon, utiliza macOS 14+ y Xcode o Command Line Tools con Swift 5.9+. La herramienta verificada es Swift 6.4 con el SDK de macOS 26. Si hace falta, ejecuta `xcode-select --install` y completa el instalador de Apple.

```sh
git clone https://github.com/wbarreto00/mac-explorer.git
cd mac-explorer
./script/test.sh
./script/build_and_run.sh
```

El script genera la app optimizada y el ZIP en `outputs/`, firma localmente y abre la app. `--build-only` compila sin abrir. Los tests no necesitan XCTest ni Xcode completo. Consulta las [notas de desarrollo en inglés](DEVELOPMENT.md).

Se aceptan contribuciones e incidencias en español. Consulta [CONTRIBUTING.md](../CONTRIBUTING.md), [SECURITY.md](../SECURITY.md) y el [historial](../CHANGELOG.md). Licencia [MIT](../LICENSE). Proyecto independiente de [wbarreto00](https://github.com/wbarreto00), sin relación con Apple ni Microsoft.
