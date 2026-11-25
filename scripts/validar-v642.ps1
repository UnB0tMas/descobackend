param(
    [string]$Servidor = 'localhost,1433',
    [string]$BaseDeDatos = 'DESCO_DB_dev2',
    [switch]$AutenticacionWindows
)

$ErrorActionPreference = 'Stop'
$archivo = Join-Path $PSScriptRoot '..\src\main\resources\db\migration\V642__AP_doc.PA_Correspondencia_Ejecutar.sql'
$compilado = Join-Path $PSScriptRoot '..\target\classes\db\migration\V642__AP_doc.PA_Correspondencia_Ejecutar.sql'
if (-not (Test-Path -LiteralPath $archivo)) { throw 'No se encontró V642 en src/main/resources.' }

$archivo = (Resolve-Path -LiteralPath $archivo).Path
$hashFuente = (Get-FileHash -LiteralPath $archivo -Algorithm SHA256).Hash
Write-Host ('V642 (src): SHA256 ' + $hashFuente)
if (Test-Path -LiteralPath $compilado) {
    $hashCompilado = (Get-FileHash -LiteralPath $compilado -Algorithm SHA256).Hash
    Write-Host ('V642 (target): SHA256 ' + $hashCompilado)
    if ($hashCompilado -ne $hashFuente) {
        throw 'V642 compilada es distinta: ejecute .\mvnw.cmd -DskipTests clean package antes de iniciar IntelliJ.'
    }
} else {
    Write-Warning 'No existe V642 en target/classes. Compile con Maven antes de iniciar.'
}

# PARSEONLY: el motor analiza la sintaxis pero no crea ni elimina objetos.
$cs = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$cs['Data Source'] = $Servidor
$cs['Initial Catalog'] = $BaseDeDatos
$cs['Encrypt'] = $true
$cs['TrustServerCertificate'] = $true
$cs['Connect Timeout'] = 15
$cs['Application Name'] = 'DESCO-Verificacion-SQL-ParseOnly'
if ($AutenticacionWindows) {
    $cs['Integrated Security'] = $true
} else {
    $credencial = Get-Credential -Message 'Ingrese la cuenta de SQL Server para validar solo sintaxis'
    if ($null -eq $credencial) { throw 'No se proporcionaron credenciales.' }
    $cs['User ID'] = $credencial.UserName
    $cs['Password'] = $credencial.GetNetworkCredential().Password
}

$contenido = [System.IO.File]::ReadAllLines($archivo)
$conexion = New-Object System.Data.SqlClient.SqlConnection($cs.ConnectionString)
$comando = $null
$parseHabilitado = $false
try {
    $conexion.Open()
    $comando = $conexion.CreateCommand()
    $comando.CommandTimeout = 120
    $comando.CommandText = 'SET PARSEONLY ON;'
    [void]$comando.ExecuteNonQuery()
    $parseHabilitado = $true
    $inicio = 1
    $fragmentos = New-Object 'System.Collections.Generic.List[string]'
    for ($i = 0; $i -le $contenido.Length; $i++) {
        $esSeparador = $i -eq $contenido.Length
        if (-not $esSeparador) { $esSeparador = $contenido[$i] -match '^\s*GO\s*(?:--.*)?$' }
        if (-not $esSeparador) {
            $fragmentos.Add($contenido[$i])
            continue
        }
        $lote = [string]::Join("`r`n", $fragmentos)
        if (-not [string]::IsNullOrWhiteSpace($lote)) {
            $comando.CommandText = $lote
            try {
                [void]$comando.ExecuteNonQuery()
            } catch [System.Data.SqlClient.SqlException] {
                Write-Host ''
                Write-Host 'FALLO DE SINTAXIS EN LA MIGRACION V642' -ForegroundColor Red
                foreach ($errorSql in $_.Exception.Errors) {
                    $fila = $inicio + [Math]::Max(0, $errorSql.LineNumber - 1)
                    Write-Host ("Numero={0}; LineaSQL={1}; LineaArchivoAproximada={2}; Mensaje={3}" -f $errorSql.Number, $errorSql.LineNumber, $fila, $errorSql.Message)
                    $desde = [Math]::Max(1, $fila - 5)
                    $hasta = [Math]::Min($contenido.Length, $fila + 5)
                    for ($j = $desde; $j -le $hasta; $j++) {
                        Write-Host ('  {0,5}: {1}' -f $j, $contenido[$j - 1])
                    }
                }
                throw 'La sintaxis V642 no es válida. Copie el bloque anterior (sin credenciales) para corregir exactamente la sentencia.'
            }
        }
        $fragmentos.Clear()
        $inicio = $i + 2
    }
    Write-Host 'V642: análisis sintáctico aprobado; no se modificó la base.' -ForegroundColor Green
} finally {
    if ($null -ne $comando) {
        if ($parseHabilitado -and $conexion.State -eq [System.Data.ConnectionState]::Open) {
            $comando.CommandText = 'SET PARSEONLY OFF;'
            try { [void]$comando.ExecuteNonQuery() } catch { }
        }
        $comando.Dispose()
    }
    $conexion.Dispose()
    if ($null -ne $credencial) { Remove-Variable credencial -ErrorAction SilentlyContinue }
}
