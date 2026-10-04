$ErrorActionPreference='Stop'
$root=Join-Path $env:TEMP ('orca-harness-test-'+[guid]::NewGuid())
New-Item -ItemType Directory -Force $root | Out-Null
Push-Location $root
try {
  git init -q; git config user.email test@example.invalid; git config user.name test
  New-Item -ItemType Directory .orca,scripts | Out-Null
  Copy-Item (Join-Path $PSScriptRoot '..\scripts\Orca-Harness.ps1') scripts\Orca-Harness.ps1
  '# plan' | Set-Content plan.md; '# acceptance' | Set-Content acceptance.md; '# request' | Set-Content request.md
  git add .; git commit -qm init
  & .\scripts\Orca-Harness.ps1 init -TaskId TEST-001 -RequestFile request.md
  & .\scripts\Orca-Harness.ps1 gate -TaskId TEST-001 -Decision approve
  & .\scripts\Orca-Harness.ps1 review -TaskId TEST-001 -Verdict approved
  & .\scripts\Orca-Harness.ps1 scope -TaskId TEST-001
  $s=Get-Content .orca-handoff\TEST-001\state.json -Raw | ConvertFrom-Json
  if ($s.planHash.Length -ne 64 -or $s.review -ne 'approved') { throw 'state assertion failed' }
  Write-Host 'PASS: initialization, gate, review, hash, and scope guard'
} finally {
  Pop-Location
  [GC]::Collect(); [GC]::WaitForPendingFinalizers()
  for ($i=0; $i -lt 5 -and (Test-Path $root); $i++) {
    try { Remove-Item $root -Recurse -Force -ErrorAction Stop } catch { Start-Sleep -Milliseconds 200 }
  }
  if (Test-Path $root) { throw "Could not remove test directory: $root" }
}
