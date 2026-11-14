param(
    [string]$Servidor = 'localhost',
    [ValidateRange(1, 65535)][int]$Puerto = 1433,
    [switch]$IniciarServicio,
    [string]$NombreServicio
)

$ErrorActionPreference = 'Stop'

if ($Servidor -in @('localhost', '127.0.0.1', '::1')) {
    $servicios = @(Get-Service -Name 'MSSQLSERVER', 'MSSQL$*' -ErrorAction SilentlyContinue)
    if ($servicios.Count -eq 0) {
        Write-Warning 'No se encontro un servicio local de motor SQL Server. Verifique su instalacion o use el servidor real.'
    } else {
        Write-Host 'Servicios locales de SQL Server:'
        $servicios | Select-Object Name, Status | Format-Table -AutoSize
    }

    if ($IniciarServicio) {
        if ($NombreServicio) {
            $seleccionado = $servicios | Where-Object { $_.Name -eq $NombreServicio } | Select-Object -First 1
        } elseif ($servicios.Count -eq 1) {
            $seleccionado = $servicios[0]
        } else {
            $seleccionado = $servicios | Where-Object { $_.Name -eq 'MSSQLSERVER' } | Select-Object -First 1
        }

        if ($null -eq $seleccionado) {
            throw 'Indique -NombreServicio con un nombre de la lista. No se iniciara una instancia arbitraria.'
        }
        if ($seleccionado.Status -ne 'Running') {
            Write-Host "Iniciando servicio $($seleccionado.Name)..."
            Start-Service -Name $seleccionado.Name
            (Get-Service -Name $seleccionado.Name).WaitForStatus('Running', [TimeSpan]::FromSeconds(30))
        }
    }
}

$cliente = $null
try {
    $cliente = [System.Net.Sockets.TcpClient]::new()
    $tarea = $cliente.ConnectAsync($Servidor, $Puerto)
    if (-not $tarea.Wait(3000) -or -not $cliente.Connected) {
        throw 'No responde el puerto indicado.'
    }
    Write-Host "OK: $Servidor`:$Puerto acepta conexiones TCP." -ForegroundColor Green
    Write-Host 'Reinicie el backend DESCO. Si hay error de credenciales o Flyway, revise el nuevo mensaje.'
} catch {
    Write-Host "ERROR: no hay conexion TCP a $Servidor`:$Puerto." -ForegroundColor Red
    Write-Host '1. Verifique que el motor de SQL Server este instalado y en ejecucion.'
    Write-Host '2. En SQL Server Configuration Manager, habilite TCP/IP para la instancia usada.'
    Write-Host '3. Confirme el puerto TCP en IPAll; reinicie el servicio si cambia la configuracion.'
    Write-Host '4. Si SQL Server usa otro host/puerto, configure DESCO_DB_URL antes de iniciar el backend.'
    exit 1
} finally {
    if ($null -ne $cliente) { $cliente.Dispose() }
}
