# Guía de uso

[English](USER_GUIDE.md) · [Português (Brasil)](USER_GUIDE.pt-BR.md) · Español · [Instalación](README.es.md#instalación)

## Navegar y organizar

Despliega las flechas de la barra lateral para navegar por las carpetas. Pulsa una carpeta para mostrar su contenido. Haz doble clic en una carpeta del área de archivos para entrar o en un archivo para abrir su aplicación asociada. La barra de ruta permite volver a carpetas superiores; ⌘L acepta una ruta absoluta o que empiece por `~`.

Haz clic derecho en una carpeta y elige **Añadir a Favoritos**, o arrastra carpetas desde el área de archivos, la barra lateral o Finder hasta **Favoritos**, a la izquierda. También puedes soltarlas sobre una carpeta de esa sección. Se guardan accesos a las ubicaciones originales sin copiar ni mover carpetas. Las adiciones repetidas no crean duplicados y la lista se conserva al cerrar la app. Haz clic derecho y elige **Quitar de Favoritos** para eliminar solo el acceso. La estrella junto a Navegación sigue añadiendo o quitando la carpeta actual.

Los discos y recursos de red aparecen cuando macOS los monta. Los favoritos de discos desconectados permanecen en la lista. La app no conecta directamente a servidores que todavía no estén montados.

En **Organizar**, elige la ordenación y la agrupación por separado. Por ejemplo, agrupa por Tipo y ordena por Modificado para ver los archivos recientes de cada tipo. El orden de los grupos es independiente del orden de sus elementos. Carpetas primero es opcional. En Detalles, haz doble clic en el encabezado de un grupo para contraerlo; en iconos, pulsa el encabezado.

**Ver** cambia el modo de presentación y las columnas. Arrastra el borde de una columna para ajustar su tamaño y su encabezado para cambiar el orden. Cada carpeta recuerda su configuración. La opción para usar la organización como predeterminada se aplica a carpetas sin configuración propia. Activa archivos ocultos y extensiones cuando los necesites.

## Selección, búsqueda y vista previa

Usa ⌘-clic para elementos separados, Mayúsculas-clic para un intervalo y ⌘A para todos los elementos visibles. La búsqueda filtra nombres en la carpeta actual; activa subcarpetas para buscar de forma recursiva. Hay un límite de 10.000 resultados; los elementos ilegibles y límites aparecen en el estado. Actualiza con ⌘R tras cambios en subcarpetas.

El panel de propiedades muestra selección, fechas, etiquetas y vistas previas de Quick Look. Los formatos dependen de macOS y de los proveedores instalados. No se calcula de forma recursiva el tamaño de las carpetas. Las etiquetas pueden esperar al proveedor de archivos; la lista normal solo las solicita cuando hacen falta.

## Operaciones

La barra, los menús y los menús contextuales ofrecen Nueva carpeta, Renombrar, Copiar, Cortar, Pegar, Copiar a, Mover a, Etiquetas y Papelera. Arrastrar y soltar copia. Separa las etiquetas por comas; un valor vacío las elimina. Con varios archivos seleccionados, las etiquetas introducidas sustituyen las de todos los elementos.

Copiar y mover conserva ambos elementos en caso de conflicto, añadiendo un número. Renombrar con un nombre ocupado se rechaza. No se fusionan carpetas automáticamente. La eliminación utiliza la Papelera de macOS.

**Deshacer movimiento** restaura el último movimiento, cambio de nombre o envío a la Papelera mientras la app siga abierta, sin sobrescribir elementos en la ruta original. Conserva una operación, no un historial completo. Copias, carpetas nuevas y etiquetas no tienen deshacer. Mantén tus copias de seguridad habituales.

## Atajos

| Acción | Atajo |
|---|---|
| Nueva ventana / nueva pestaña | ⌘N / ⌘T |
| Cerrar pestaña / siguiente | ⌘⇧W / Control+Tab |
| Nueva carpeta / buscar | ⌘⇧N / ⌘F |
| Ir a carpeta | ⌘L |
| Atrás / adelante / superior | ⌘← / ⌘→ / ⌘↑ |
| Abrir selección | ⌘↓ o Intro |
| Copiar / cortar / pegar | ⌘C / ⌘X / ⌘V |
| Seleccionar todo | ⌘A |
| Renombrar en Detalles/Lista | F2 o fn+F2 |
| Propiedades y vista previa | Espacio o ⌘⌥I |
| Actualizar / archivos ocultos | ⌘R / ⌘⇧. |
| Mover a la Papelera | ⌘⌫ |
| Deshacer movimiento | ⌘⌥Z |
| Ajustes de idioma y permisos | ⌘, |

## Permisos de acceso a archivos

Abre **Mac Explorer → Ajustes… → Permisos** (⌘,) y pulsa **Abrir acceso total al disco…**. Esta opción concede acceso amplio a archivos protegidos, incluidos datos de otras apps y copias de seguridad. Puedes seguir usando permisos por carpeta si prefieres limitar el acceso.

En los Ajustes del Sistema, activa Mac Explorer. Si no aparece, usa **+** para añadirlo; **Mostrar app en Finder** localiza la copia que estás ejecutando. Autentícate con Touch ID o la contraseña del Mac cuando macOS lo solicite; después, cierra y vuelve a abrir la app. La aplicación no puede concederse el permiso ni autenticarse por ti. Si el acceso directo no funciona, abre manualmente **Ajustes del Sistema → Privacidad y seguridad → Acceso total al disco**.

Esta versión usa firma ad hoc. Actualizar o recompilar la app puede cambiar la identidad que macOS utiliza para recordar los permisos y requerir otra autorización. El acceso total al disco no resuelve esta limitación de firma ni proporciona notarización de Apple.

## Problemas habituales

- **App bloqueada:** consulta la firma y las instrucciones de Apple en [Instalación](README.es.md#instalación).
- **No se puede leer una carpeta:** comprueba su existencia, la conexión del disco y los permisos de Archivos y carpetas de macOS. Actualiza después de reconectar el volumen.
- **No cambió el idioma:** cierra la app por completo y vuelve a abrirla. La elección está en Mac Explorer → Ajustes; los formatos regionales son independientes.
- **Búsqueda desactualizada:** pulsa ⌘R. Observar la carpeta abierta no supervisa todas sus subcarpetas.
- **Función ausente:** revisa el alcance en el [README](README.es.md). Al informar de un problema, incluye versiones y pasos para reproducirlo, sin contenidos personales.
