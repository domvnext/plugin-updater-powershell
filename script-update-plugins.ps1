# Función para cambiar el color del texto
function Write-Color {
    param(
        [string]$Text,
        [ConsoleColor]$Color
    )
    $currentColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $Color
    Write-Host $Text
    $Host.UI.RawUI.ForegroundColor = $currentColor
}

Start-Transcript .\resultados.txt | out-null

# Ruta del fichero de plugins.txt
$pluginFilePath = "plugins.txt"
# Ruta del nuevo fichero de salida con versiones actualizadas
$updatedPluginFilePath = "plugins_actualizados.txt"
$updatedPluginFilePath_IPNCCIS = "plugins_ipnccis.txt"

# URL del JSON del Jenkins Update Center
$updateCenterUrl = "https://updates.jenkins.io/update-center.json"

# Descargar el contenido del JSON
$updateCenterJson = (Invoke-RestMethod -Uri $updateCenterUrl -UseBasicParsing).ToString()

# Limpiar la respuesta (quitar la parte de post y los paréntesis)
$updateCenterCleaned = $updateCenterJson -replace "^updateCenter\.post\(","" -replace "\);\s*$",""

# Volcamos a fichero
$updateCenterCleaned | ConvertFrom-Json | ConvertTo-Json -Depth 5   | Out-File "update-center.json" -Encoding utf8

# Convertir el JSON en un objeto PowerShell
$updateCenterData = $updateCenterCleaned | ConvertFrom-Json

# Obtener la lista de plugins del Update Center
$pluginsUpdateCenterNAME = $updateCenterData.plugins.PSObject.Properties.Name
$pluginsUpdateCenterTITLE = $updateCenterData.plugins |ForEach-Object {$_.PSObject.Properties.Value.title}
$pluginsUpdateCenterRequiredCore = $updateCenterData.plugins |ForEach-Object {$_.PSObject.Properties.Value.requiredCore}
$pluginsUpdateCenterVALUES = $updateCenterData.plugins |ForEach-Object {$_.PSObject.Properties.Value}

# Leer los plugins del fichero y procesarlos
(Get-Content $pluginFilePath) | Where-Object { $_.Trim() -ne "" } | Set-Content $pluginFilePath
$pluginData = Get-Content $pluginFilePath.trim() | ForEach-Object {
    if($_ -ne $null -and $_ -ne ''){
        $pluginInfo = $_ -split ":"
        [PSCustomObject]@{
            Name = $pluginInfo[0]
            Version = $pluginInfo[1]
        }
    }
}

# Diccionario para almacenar los plugins existentes
$existingPlugins = @{}
foreach ($plugin in $pluginData) {
    $existingPlugins[$plugin.Name] = $plugin.Version
}

# Lista para almacenar los plugins actualizados
$updatedPlugins = @()

foreach ($plugin in $pluginData) {
    $pluginName = $plugin.Name
    $currentVersion = $plugin.Version
    if(!($currentVersion)){$currentVersion=0}

    if(!($pluginsUpdateCenterNAME | Where-Object { $_ -ceq $pluginName })){
        if($pluginsUpdateCenterTitle -contains $pluginName){
            # $pluginName=($pluginsUpdateCenterVALUES |Where-Object {$_.title -eq $pluginName}).name
            $pluginName=((($pluginsUpdateCenterVALUES |Where-Object {$_.title -eq $pluginName}).url).split("/")[-1]).replace(".hpi","").trim()
        }
        else{
            Write-Color "[ERR] Plugin $pluginName no encontrado ni por nombre ni por id!"  -Color Red
        }
    }

    # Buscar la última versión del plugin en el Update Center
    if ($pluginsUpdateCenterNAME -contains $pluginName) {
        $latestVersion = $updateCenterData.plugins.$pluginName.version
        
        if ($currentVersion -ne $latestVersion) {
            Write-Host "El plugin '$pluginName' está desactualizado. Versión actual: $currentVersion, Última versión: $latestVersion"
            $updatedPlugins += $pluginName + ":" + $latestVersion
        } else {
            Write-Host "El plugin '$pluginName' está actualizado."
            $updatedPlugins += $pluginName + ":" + $currentVersion
        }

        # Revisar dependencias obligatorias del plugin (ignorar dependencias opcionales)
        $dependencies = $updateCenterData.plugins.$pluginName.dependencies
        foreach ($dependency in $dependencies) {
            $depName = $dependency.name
            $isOptional = $dependency.optional -eq $true
            # Solo procesar si la dependencia NO es opcional y no existe ya en el archivo
            if (-not $isOptional -and -not $existingPlugins.ContainsKey($depName)) {
                if ($pluginsUpdateCenterNAME -contains $depName) {
                    $latestDepVersion = $updateCenterData.plugins.$depName.version
                    Write-Color "La dependencia '$depName' no existe, añadiendo con la última versión $latestDepVersion." -Color Yellow
                    $updatedPlugins += $depName + ":" + $latestDepVersion
                }
            }
        }
    } else {
        Write-Host "El plugin '$pluginName' no se encontró en el Jenkins Update Center."
        $updatedPlugins += $pluginName + ":" + $currentVersion
    }
}

# Guardar los plugins actualizados en el nuevo fichero
$updatedPlugins | Sort-Object | Get-Unique | Set-Content -Path $updatedPluginFilePath


$pluginsUpdateCenterRequiredCore | Select-Object -Unique  | ForEach-Object { [System.Version]$_ } | Sort-Object | Select-Object -Last 2
# blueocean-config.hpi\META-INF\MANIFEST.MF

Write-Host "Fichero actualizado generado en: $updatedPluginFilePath"

Stop-Transcript 