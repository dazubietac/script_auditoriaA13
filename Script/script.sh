<#
.SYNOPSIS
    Script de auditoría de VPN para verificar la IP pública y el DNS activo.
.DESCRIPTION
    Este script contacta servicios externos para determinar la IP pública
    y el servidor DNS que se está utilizando actualmente.
    Debe ejecutarse ANTES y DESPUÉS de conectar la VPN para comparar resultados.
.AUTHOR
    Asistente de programación
#>

# Establecer la política de seguridad solo para este proceso (si es necesario)
# Set-ExecutionPolicy RemoteSigned -Scope Process -Force

Write-Host "--- Iniciando Verificación de Conexión ---" -ForegroundColor Cyan

# --- 1. Verificación de IP Pública ---
Write-Host "`n[PASO 1] Verificando la IP pública y la ubicación..."
try {
    # Usamos el servicio 'ipinfo.io' porque nos da la IP y el proveedor (ASN)
    # El parámetro -UseBasicParsing es bueno para compatibilidad
    $ipInfo = Invoke-RestMethod -Uri 'https://ipinfo.io/json' -UseBasicParsing

    Write-Host "  [RESULTADO] IP Pública:  " -NoNewline
    Write-Host "$($ipInfo.ip)" -ForegroundColor Green

    Write-Host "  [RESULTADO] Ubicación: " -NoNewline
    Write-Host "$($ipInfo.city), $($ipInfo.country)" -ForegroundColor Green
    
    Write-Host "  [RESULTADO] Proveedor: " -NoNewline
    Write-Host "$($ipInfo.org)" -ForegroundColor Green

} catch {
    Write-Warning "ERROR: No se pudo obtener la IP pública."
    Write-Warning $_.Exception.Message
}

# --- 2. Verificación de Fuga de DNS ---
Write-Host "`n[PASO 2] Verificando el servidor DNS activo..."
try {
    # Hacemos una consulta 'nslookup' a un dominio aleatorio.
    # El servidor que responde ('Server:') es el DNS que tu sistema está usando.
    # '2>&1' redirige los errores (si los hay) a la salida estándar
    $nslookupResult = nslookup -timeout=2 "google.com" 2>&1

    # Filtramos la salida de nslookup para encontrar la línea que dice "Server:"
    $dnsServerLine = $nslookupResult | Select-String 'Server:' | Select-Object -First 1

    if ($dnsServerLine) {
        # Limpiamos el texto para mostrar solo el nombre o IP del servidor
        $dnsServer = $dnsServerLine.ToString().Split(':')[-1].Trim()
        
        Write-Host "  [RESULTADO] Servidor DNS en uso: " -NoNewline
        Write-Host "$dnsServer" -ForegroundColor Green
        
    } else {
        Write-Warning "ADVERTENCIA: No se pudo determinar el servidor DNS (nslookup falló)."
    }

} catch {
    Write-Warning "ERROR: Falló la ejecución de nslookup."
    Write-Warning $_.Exception.Message
}

Write-Host "`n--- Verificación Completada ---" -ForegroundColor Cyan
Write-Host "Recuerda comparar estos resultados (IP, Ubicación, Proveedor y DNS) con los de la conexión alternativa (VPN activada/desactivada)."