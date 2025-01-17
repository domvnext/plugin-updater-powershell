# Jenkins Plugin Updater
==========================

Este script actualiza los plugins de Jenkins a partir de la información proporcionada por el Jenkins Update Center.

## Requisitos
------------

* PowerShell 5 o superior
* Acceso a Internet para descargar el contenido del Update Center

## Uso
-----

1. Edita el archivo `plugins.txt` para agregar o eliminar plugins.
2. Ejecuta el script con el comando `.\script.ps1`
3. El script generará un nuevo archivo `plugins_actualizados.txt` con las versiones actualizadas de los plugins.

## Configuración
--------------

* El script utiliza la URL del Update Center configurada en la variable `$updateCenterUrl`.
* El archivo `plugins.txt` debe contener la lista de plugins a actualizar, con el nombre y versión de cada plugin separados por un colon (`:`).

## Tratamiento de dependencias
---------------------------

El script también se encarga de actualizar las dependencias de los plugins. Si un plugin tiene dependencias obligatorias, el script las identificará y las actualizará a la última versión disponible en el Update Center. Las dependencias opcionales no se actualizarán.

El script utiliza el siguiente algoritmo para tratar las dependencias:

1. Identifica las dependencias obligatorias de cada plugin en el Update Center.
2. Compara las versiones de las dependencias obligatorias con las versiones actuales en el archivo `plugins.txt`.
3. Si una dependencia obligatoria no existe en el archivo `plugins.txt`, se agrega con la última versión disponible en el Update Center.
4. Si una dependencia obligatoria tiene una versión inferior a la última disponible en el Update Center, se actualiza a la versión más reciente.

## Notas
-----

* El script utiliza el comando `Invoke-RestMethod` para descargar el contenido del Update Center.
* El script utiliza el comando `ConvertFrom-Json` para convertir el contenido del Update Center en un objeto PowerShell.
* El script utiliza el comando `Set-Content` para escribir el contenido del archivo `plugins_actualizados.txt`.

## Código
-----

El código del script se encuentra en el archivo `script.ps1`. Puedes editar el archivo para personalizar el comportamiento del script.

## Licencia
----------

Este script está bajo la licencia MIT. Puedes utilizar y modificar el código según tus necesidades.

## Autor
------

Este script fue creado por [Tu nombre] en [Fecha].
