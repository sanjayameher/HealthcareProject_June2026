$ports = @(5001, 7081, 7082, 7083, 7084, 7085, 7086)
for ($i = 0; $i -lt 40; $i++) {
  $allUp = $true
  foreach ($p in $ports) {
    $owner = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
    if (-not $owner) { $allUp = $false }
  }
  if ($allUp) {
    Write-Output "ALL_UP"
    break
  }
  Start-Sleep -Seconds 3
}
foreach ($p in $ports) {
  $owner = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
  if ($owner) { Write-Output "$p : UP" } else { Write-Output "$p : DOWN" }
}
