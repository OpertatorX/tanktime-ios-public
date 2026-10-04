param(
  [string]$Repo = 'OpertatorX/tanktime-ios-public',
  [string]$AppId = '',
  [string]$BannerId = '',
  [string]$InterstitialId = ''
)
$ErrorActionPreference = 'Stop'
$Publisher = '9441192520255287'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
function Set-RepoSecret([string]$Name, [string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { throw "Secret $Name is empty." }
  gh secret set $Name --repo $Repo --body $Value
  if ($LASTEXITCODE -ne 0) { throw "Failed to set $Name." }
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI (gh) is required.' }
gh auth status | Out-Null
if (-not $AppId -or -not $BannerId -or -not $InterstitialId) {
  if (-not (Get-Command python -ErrorAction SilentlyContinue)) { throw 'Python is required to bootstrap AdMob.' }
  python -m pip install --quiet requests
  python "$PSScriptRoot\bootstrap_admob.py"
  if ($LASTEXITCODE -ne 0) { throw 'AdMob API bootstrap failed.' }
  $privatePath = Join-Path $Root '.factory-private\tanktime-admob.json'
  if (-not (Test-Path $privatePath)) { throw 'AdMob bootstrap did not produce the expected private output.' }
  $inventory = Get-Content $privatePath -Raw | ConvertFrom-Json
  $AppId = $inventory.appId; $BannerId = $inventory.bannerId; $InterstitialId = $inventory.interstitialId
}
if ($AppId -notmatch "^ca-app-pub-$Publisher~[0-9]+$") { throw 'Invalid TankTime AdMob App ID.' }
if ($BannerId -notmatch "^ca-app-pub-$Publisher/[0-9]+$") { throw 'Invalid TankTime banner ad unit ID.' }
if ($InterstitialId -notmatch "^ca-app-pub-$Publisher/[0-9]+$") { throw 'Invalid TankTime interstitial ad unit ID.' }
Set-RepoSecret 'TANKTIME_ADMOB_APP_ID' $AppId
Set-RepoSecret 'TANKTIME_ADMOB_BANNER_ID' $BannerId
Set-RepoSecret 'TANKTIME_ADMOB_INTERSTITIAL_ID' $InterstitialId
Write-Host 'PASS: TankTime production AdMob IDs are installed in GitHub secrets.' -ForegroundColor Green
