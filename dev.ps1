<#
  dev.ps1  -  Sobe o ambiente de testes do SATI-UUA em janelas separadas.
  ------------------------------------------------------------------------
  Uso (PowerShell, dentro de D:\desenvolvimento\flutter\chamados):

      .\dev.ps1            # só o backend (API na 8090)
      .\dev.ps1 -Apk       # backend + servidor de download do APK (9090)
      .\dev.ps1 -Web       # backend + app web acessível na rede (8000)
      .\dev.ps1 -Apk -Web  # tudo junto

  Cada serviço abre na PRÓPRIA janela (você vê os logs e para com Ctrl+C
  ou fechando a janela). O script libera a porta 8090 antes de subir o
  backend, então resolve sozinho o "endereço já em uso".

  Se o PowerShell reclamar de execução de script, rode assim uma vez:
      powershell -ExecutionPolicy Bypass -File .\dev.ps1 -Apk -Web

  ------------------------------------------------------------------------
  FALLBACK MANUAL (se precisar rodar na mão, sem este script):

      Backend : cd server ;  dart run bin/server.dart
      APK     : cd mobile ;  flutter build apk --debug
                cd ..     ;  dart run apk_server.dart      (celular abre http://IP:9090)
      Web     : cd mobile ;  flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8000
      Celular : cd mobile ;  flutter run                  (com cabo USB + depuração ativa)

  Firewall (uma vez, PowerShell como ADMIN) para outros aparelhos alcançarem:
      New-NetFirewallRule -DisplayName "SATI-UUA dev" -Direction Inbound `
        -Protocol TCP -LocalPort 8090,9090,8000 -Action Allow
  ------------------------------------------------------------------------
#>

param(
  [switch]$Apk,
  [switch]$Web
)

$ErrorActionPreference = 'Stop'
$root   = $PSScriptRoot
$server = Join-Path $root 'server'
$mobile = Join-Path $root 'mobile'

# IP LAN desta máquina (para imprimir as URLs certas).
$ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -match '^(192\.168|10\.|172\.(1[6-9]|2\d|3[01]))\.' } |
        Select-Object -First 1 -ExpandProperty IPAddress)
if (-not $ip) { $ip = '192.168.101.6' }

function Free-Port([int]$port) {
  $conns = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
  foreach ($c in $conns) {
    Write-Host "Liberando porta $port (PID $($c.OwningProcess))..." -ForegroundColor Yellow
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
  }
}

function Start-InWindow([string]$title, [string]$workdir, [string]$command) {
  Start-Process powershell -ArgumentList @(
    '-NoExit', '-Command',
    "`$host.UI.RawUI.WindowTitle='$title'; Set-Location '$workdir'; $command"
  )
}

Write-Host "== SATI-UUA dev ==  IP desta maquina: $ip" -ForegroundColor Cyan

# Aviso se o app aponta para um IP diferente do atual (o base URL e' fixo).
$apiClient = Join-Path $mobile 'lib\core\network\api_client.dart'
if (Test-Path $apiClient) {
  $m = Select-String -Path $apiClient -Pattern "_kBaseUrl\s*=\s*'http://([\d.]+):"
  if ($m) {
    $configured = $m.Matches[0].Groups[1].Value
    if ($configured -ne $ip) {
      Write-Host "AVISO: o app chama a API em $configured, mas esta maquina e' $ip." -ForegroundColor Red
      Write-Host "       Ajuste _kBaseUrl em api_client.dart ou fixe o IP no roteador," -ForegroundColor Red
      Write-Host "       senao os outros aparelhos nao vao achar a API." -ForegroundColor Red
    }
  }
}

# ── Backend (sempre) ─────────────────────────────────────────────────────────
Free-Port 8090
Start-InWindow 'SATI-UUA API (8090)' $server 'dart run bin/server.dart'
Write-Host "API  -> http://$ip`:8090   (health: /health)" -ForegroundColor Green

# ── APK (opcional) ───────────────────────────────────────────────────────────
if ($Apk) {
  Write-Host "Gerando APK debug (pode demorar no primeiro build)..." -ForegroundColor Yellow
  Push-Location $mobile
  flutter build apk --debug
  Pop-Location
  Free-Port 9090
  Start-InWindow 'SATI-UUA APK (9090)' $root 'dart run apk_server.dart'
  Write-Host "APK  -> http://$ip`:9090   (abra no navegador do CELULAR e instale)" -ForegroundColor Green
}

# ── Web (opcional) ───────────────────────────────────────────────────────────
if ($Web) {
  Free-Port 8000
  Start-InWindow 'SATI-UUA Web (8000)' $mobile 'flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8000'
  Write-Host "WEB  -> http://$ip`:8000   (abra em QUALQUER aparelho da rede; compila na 1a vez)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Cada servico esta numa janela propria. Para parar: Ctrl+C ou feche a janela." -ForegroundColor Cyan
Write-Host "Celular por cabo (hot reload):  cd mobile ; flutter run" -ForegroundColor DarkGray
