[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('init','status','gate','review','fix','scope','safe-commit','safe-push','deploy-check','cleanup')][string]$Command,
  [string]$TaskId, [string]$RequestFile, [ValidateSet('approve','reject')][string]$Decision,
  [ValidateSet('approved','changes_requested','blocked')][string]$Verdict,
  [string]$Message
)
$ErrorActionPreference = 'Stop'
$root = (Get-Location).Path
$handoff = Join-Path $root '.orca-handoff'
function NeedTask { if ([string]::IsNullOrWhiteSpace($TaskId)) { throw 'TaskId is required, for example -TaskId TASK-001' }; if ($TaskId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$') { throw 'TaskId contains unsupported characters' } }
function Get-TaskDir { NeedTask; $d=Join-Path $handoff $TaskId; New-Item -ItemType Directory -Force -Path $d | Out-Null; return $d }
function Read-State($d) { $p=Join-Path $d 'state.json'; if (!(Test-Path $p)) { throw "Task is not initialized: $TaskId" }; return Get-Content $p -Raw | ConvertFrom-Json }
function Save-State($d,$s) { $s.updatedAt=(Get-Date).ToUniversalTime().ToString('o'); $s | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $d 'state.json') -Encoding utf8 }
function Hash-File($path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() }
function ChangedFiles { @(git -c core.quotepath=false status --short | ForEach-Object { if ($_ -match '^...\s+(.+)$') { $matches[1].Trim('"') } }) }
switch ($Command) {
 'init' {
   $d=Get-TaskDir; if (!$RequestFile) { $RequestFile='request.md' }; if (!(Test-Path $RequestFile)) { throw "Request file not found: $RequestFile" }
   $plan=Join-Path $root 'plan.md'; $accept=Join-Path $root 'acceptance.md'
   if (!(Test-Path $plan)) { throw 'Create plan.md before init' }; if (!(Test-Path $accept)) { throw 'Create acceptance.md before init' }
   $s=[ordered]@{ taskId=$TaskId; phase='planned'; gate='pending'; review='pending'; fixCount=0; planHash=(Hash-File $plan); requestHash=(Hash-File $RequestFile); allowedFiles=@(); createdAt=(Get-Date).ToUniversalTime().ToString('o'); updatedAt='' }
   Save-State $d ([pscustomobject]$s); Copy-Item $plan (Join-Path $d 'plan.snapshot.md') -Force; Copy-Item $accept (Join-Path $d 'acceptance.snapshot.md') -Force
   Write-Host "initialized $TaskId with plan hash $($s.planHash)"
 }
 'status' { $d=Get-TaskDir; $s=Read-State $d; $s | ConvertTo-Json -Depth 8 }
 'gate' { if ($Decision -notin @('approve','reject')) { throw '-Decision approve or reject is required' }; $d=Get-TaskDir; $s=Read-State $d; if ($Decision -eq 'approve') { $s.gate='approved'; $s.phase='ready_for_implementation' } else { $s.gate='rejected'; $s.phase='blocked' }; Save-State $d $s; Write-Host "gate=$($s.gate)" }
 'review' { if (!$Verdict) { throw '-Verdict is required' }; $d=Get-TaskDir; $s=Read-State $d; $s.review=$Verdict; $s.phase= if ($Verdict -eq 'approved') {'review_approved'} elseif ($Verdict -eq 'blocked') {'blocked'} else {'changes_requested'}; if ($Verdict -eq 'approved') { $s.gate='approved' }; Save-State $d $s; if ($Message) { $Message | Set-Content (Join-Path $d 'review.md') -Encoding utf8 }; Write-Host "review=$Verdict" }
 'fix' { $d=Get-TaskDir; $s=Read-State $d; if ($s.review -ne 'changes_requested') { throw 'Fix is allowed only after changes_requested' }; if ([int]$s.fixCount -ge 2) { $s.phase='blocked'; Save-State $d $s; throw 'Maximum of 2 fixes reached; human decision required' }; $s.fixCount=[int]$s.fixCount+1; $s.phase='fixing'; Save-State $d $s; Write-Host "fix attempt $($s.fixCount)/2" }
 'scope' { $d=Get-TaskDir; $s=Read-State $d; $plan=Join-Path $root 'plan.md'; if ((Hash-File $plan) -ne $s.planHash) { throw 'Plan hash changed after init; fail-closed' }; $files=ChangedFiles; $forbidden=@('.env','.env.local','.orca-handoff','AGENTS.md'); $bad=@($files | Where-Object { $f=$_; $forbidden | Where-Object { $f -like "$_*" } }); if ($bad.Count) { $bad | Set-Content (Join-Path $d 'out-of-scope.txt') -Encoding utf8; throw "Out-of-scope or sensitive files detected: $($bad -join ', ')" }; $s.phase='scope_clean'; Save-State $d $s; Write-Host 'scope=clean' }
 'safe-commit' { if (!$Message) { throw '-Message is required' }; $d=Get-TaskDir; $s=Read-State $d; if ($s.gate -ne 'approved' -or $s.review -ne 'approved' -or $s.phase -ne 'scope_clean') { throw 'Commit guard: gate, review, and scope must all be approved/clean' }; git add --all; git commit -m $Message }
 'safe-push' { $d=Get-TaskDir; $s=Read-State $d; if ($s.gate -ne 'approved' -or $s.review -ne 'approved') { throw 'Push guard: gate and review must be approved' }; git push }
 'deploy-check' { $d=Get-TaskDir; $s=Read-State $d; if ($s.review -ne 'approved') { throw 'Deploy guard: review is not approved' }; Write-Host 'deploy=eligible; run the project-specific deploy command only after human confirmation' }
 'cleanup' { $d=Get-TaskDir; $s=Read-State $d; if ($s.phase -notin @('review_approved','blocked')) { throw 'Cleanup is allowed only after review completion or block' }; Remove-Item -LiteralPath (Join-Path $root '.orca-workers') -Recurse -Force -ErrorAction SilentlyContinue; Write-Host 'worker cleanup complete; handoff evidence preserved' }
}
