$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
if ($payload.toolName -ne 'powershell') { exit 0 }

$toolArgs = $payload.toolArgs
if ($toolArgs -is [string]) {
    $toolArgs = $toolArgs | ConvertFrom-Json
}
if ($toolArgs.command -cnotmatch 'git commit') { exit 0 }

$errors = @()
Push-Location -LiteralPath $payload.cwd
try {
    # 1. TypeScript type check
    if (Test-Path -LiteralPath 'tsconfig.json' -PathType Leaf) {
        $tscOutput = & npx tsc --noEmit 2>&1
        if ($LASTEXITCODE -ne 0) {
            $errors += "=== TypeScript Errors ===`n$(($tscOutput | Select-Object -First 30) -join "`n")"
        }
    }

    # 2. Lint
    if (Test-Path -LiteralPath 'package.json' -PathType Leaf) {
        $package = Get-Content -LiteralPath 'package.json' -Raw | ConvertFrom-Json
        if ($package.scripts.lint) {
            $lintOutput = & npm run lint --silent 2>&1
            if ($LASTEXITCODE -ne 0) {
                $errors += "=== Lint Errors ===`n$(($lintOutput | Select-Object -Last 30) -join "`n")"
            }
        }

        # 3. Tests
        # if ($package.scripts.test) {
        #     $previousCI = $env:CI
        #     try {
        #         $env:CI = 'true'
        #         $testOutput = & npm test -- --watchAll=false 2>&1
        #         if ($LASTEXITCODE -ne 0) {
        #             $errors += "=== Test Failures ===`n$(($testOutput | Select-Object -Last 30) -join "`n")"
        #         }
        #     }
        #     finally {
        #         $env:CI = $previousCI
        #     }
        # }
    }
}
finally {
    Pop-Location
}

if ($errors.Count -gt 0) {
    @{
        permissionDecision = 'deny'
        permissionDecisionReason = "Cannot commit - fix these issues first:`n$($errors -join "`n")"
    } | ConvertTo-Json -Compress
}
exit 0
