# flutter_ci.ps1
# Local CI deployment commands for NotesApp.
# Source from a terminal:  . "D:\Android_Dev\Flutter\Projects\notesapp\deployment\flutter_ci.ps1"
#
# Required local env vars (loaded automatically from deployment/.env.ps1):
#   GITHUB_TOKEN      — PAT with 'repo' and 'workflow' scopes
#   MAIL_USERNAME     — Gmail address used to send notifications
#   MAIL_APP_PASSWORD — Gmail App Password (not your real password)
#   TESTER_EMAILS     — Comma-separated list of tester email addresses

$_envFile = Join-Path $PSScriptRoot ".env.ps1"
if (Test-Path $_envFile) { . $_envFile }


Set-StrictMode -Off

$script:REPO = "TheMirza009/notesapp"
$script:APK_PATH = "build\app\outputs\flutter-apk\app-rc-release.apk"

# ─────────────────────────────────────────────────────────────────────────────
# deploy-test
# Build RC APK → ADB install → git push → GitHub Pre-Release → email testers
# ─────────────────────────────────────────────────────────────────────────────
function deploy-test {
    Push-Location "d:\Android_Dev\Flutter\Projects\notesapp"

    try {
        # 1. Build APK
        Write-Host "`nBuilding RC APK..." -ForegroundColor Cyan
        flutter build apk --release --flavor rc
        if ($LASTEXITCODE -ne 0) { Write-Host "Build failed." -ForegroundColor Red; return }

        # 2. ADB install (conditional)
        $serials = adb devices 2>&1 |
            Where-Object { $_ -match "\bdevice$" } |
            ForEach-Object { ($_ -split "\s+")[0] }

        if (-not $serials) {
            Write-Host "No device connected. Skipping ADB install." -ForegroundColor Yellow
        } elseif (@($serials).Count -eq 1) {
            Write-Host "Installing APK on $serials..." -ForegroundColor Cyan
            adb -s $serials install -r $script:APK_PATH
        } else {
            Write-Host "`nMultiple devices connected:" -ForegroundColor Cyan
            $i = 1
            foreach ($s in $serials) { Write-Host "  [$i] $s"; $i++ }
            $pick = Read-Host "Select device number"
            $serial = @($serials)[[int]$pick - 1]
            Write-Host "Installing APK on $serial..." -ForegroundColor Cyan
            adb -s $serial install -r $script:APK_PATH
        }

        # 3. Git commit + push
        git add .
        $commitMsg = Read-Host "`nCommit message"
        if (-not $commitMsg) { Write-Host "Commit message cannot be empty." -ForegroundColor Red; return }
        git commit -m $commitMsg
        $branch = git rev-parse --abbrev-ref HEAD
        git push origin $branch
        if ($LASTEXITCODE -ne 0) { Write-Host "Git push failed." -ForegroundColor Red; return }

        $sha      = git rev-parse --short HEAD
        $fullSha  = git rev-parse HEAD

        # 4. Create GitHub Pre-Release + upload APK
        $token = $env:GITHUB_TOKEN
        if (-not $token) { Write-Host "GITHUB_TOKEN not set. Skipping GitHub Release." -ForegroundColor Yellow; return }

        $headers = @{
            Authorization  = "Bearer $token"
            "Content-Type" = "application/json"
            Accept         = "application/vnd.github+json"
        }
        $tagName = "test-$sha"

        # Create annotated tag object
        $tagObj = @{ tag = $tagName; message = "Test build $sha"; object = $fullSha; type = "commit" } | ConvertTo-Json
        Invoke-RestMethod -Uri "https://api.github.com/repos/$script:REPO/git/tags" `
            -Method Post -Headers $headers -Body $tagObj | Out-Null

        # Create tag ref
        $refObj = @{ ref = "refs/tags/$tagName"; sha = $fullSha } | ConvertTo-Json
        Invoke-RestMethod -Uri "https://api.github.com/repos/$script:REPO/git/refs" `
            -Method Post -Headers $headers -Body $refObj | Out-Null

        # Create pre-release
        $releaseObj = @{
            tag_name   = $tagName
            name       = "Test Build $sha"
            body       = "Commit: $fullSha`nBranch: $branch"
            prerelease = $true
            draft      = $false
        } | ConvertTo-Json
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$script:REPO/releases" `
            -Method Post -Headers $headers -Body $releaseObj

        # Upload APK asset
        $uploadUrl  = $release.upload_url -replace '\{.*\}', ''
        $apkBytes   = [IO.File]::ReadAllBytes((Resolve-Path $script:APK_PATH))
        $uploadHeaders = @{
            Authorization  = "Bearer $token"
            "Content-Type" = "application/vnd.android.package-archive"
            Accept         = "application/vnd.github+json"
        }
        Invoke-RestMethod -Uri "${uploadUrl}?name=notesapp-rc-${sha}.apk" `
            -Method Post -Headers $uploadHeaders -Body $apkBytes | Out-Null

        $releaseUrl = $release.html_url
        Write-Host "Release created: $releaseUrl" -ForegroundColor Green

        # 5. Email testers
        _Send-TestEmail -Sha $sha -FullSha $fullSha -Branch $branch -ReleaseUrl $releaseUrl
    }
    finally {
        Pop-Location
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# deploy-prod
# Warning + confirm → git push → trigger GitHub Actions → Play Store → email
# ─────────────────────────────────────────────────────────────────────────────
function deploy-prod {
    Push-Location "d:\Android_Dev\Flutter\Projects\notesapp"

    try {
        # 1. Warning + confirm
        $sha       = git rev-parse --short HEAD
        $lastMsg   = git log -1 --pretty=%s

        Write-Host ""
        Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "   WARNING: PRODUCTION DEPLOYMENT"         -ForegroundColor Red
        Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host "   Last commit : $sha — $lastMsg"          -ForegroundColor White
        Write-Host "   This will go LIVE for ALL users"        -ForegroundColor Red
        Write-Host "══════════════════════════════════════════" -ForegroundColor Yellow
        Write-Host ""

        $confirm = Read-Host "Type 'yes' to continue"
        if ($confirm -ne "yes") { Write-Host "Cancelled." -ForegroundColor Yellow; return }

        # 2. Collect release notes (blank line to finish)
        Write-Host "`nEnter release notes (blank line to finish):" -ForegroundColor Cyan
        $lines = @()
        while ($true) {
            $line = Read-Host
            if ($line -eq "") { break }
            $lines += $line
        }
        $releaseNotes = $lines -join "`n"
        if (-not $releaseNotes) { Write-Host "Release notes cannot be empty." -ForegroundColor Red; return }

        # 3. Git push
        $branch = git rev-parse --abbrev-ref HEAD
        git push origin $branch
        if ($LASTEXITCODE -ne 0) { Write-Host "Git push failed. Aborting." -ForegroundColor Red; return }

        # 4. Trigger GitHub Actions workflow
        $token = $env:GITHUB_TOKEN
        if (-not $token) { Write-Host "GITHUB_TOKEN not set." -ForegroundColor Red; return }

        $body = @{
            ref    = "main"
            inputs = @{ release_notes = $releaseNotes }
        } | ConvertTo-Json

        Invoke-RestMethod `
            -Uri "https://api.github.com/repos/$script:REPO/actions/workflows/deploy_prod.yml/dispatches" `
            -Method Post `
            -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json"; Accept = "application/vnd.github+json" } `
            -Body $body | Out-Null

        Write-Host "`nProduction deployment triggered. Check GitHub Actions for progress." -ForegroundColor Green
        Write-Host "https://github.com/$script:REPO/actions" -ForegroundColor Cyan
    }
    finally {
        Pop-Location
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Internal helper — send test build email via SMTP
# ─────────────────────────────────────────────────────────────────────────────
function _Send-TestEmail {
    param($Sha, $FullSha, $Branch, $ReleaseUrl)

    $mailUser  = $env:MAIL_USERNAME
    $mailPass  = $env:MAIL_APP_PASSWORD
    $recipients = $env:TESTER_EMAILS

    if (-not $mailUser -or -not $mailPass -or -not $recipients) {
        Write-Host "Email env vars not set (MAIL_USERNAME, MAIL_APP_PASSWORD, TESTER_EMAILS). Skipping email." -ForegroundColor Yellow
        return
    }

    $smtp = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
    $smtp.EnableSsl  = $true
    $smtp.Credentials = New-Object System.Net.NetworkCredential($mailUser, $mailPass)

    $msg          = New-Object System.Net.Mail.MailMessage
    $msg.From     = $mailUser
    $msg.Subject  = "[?] Test Build Ready -- $Sha"
    $msg.Body     = "A new test build is ready.`n`nCommit : $FullSha`nBranch : $Branch`n`nDownload : $ReleaseUrl"
    $msg.IsBodyHtml = $false

    foreach ($addr in ($recipients -split ',')) {
        $trimmed = $addr.Trim()
        if ($trimmed) { $msg.To.Add($trimmed) }
    }

    try {
        $smtp.Send($msg)
        Write-Host "Email sent to testers." -ForegroundColor Green
    } catch {
        Write-Host "Failed to send email: $_" -ForegroundColor Red
    } finally {
        $msg.Dispose()
        $smtp.Dispose()
    }
}
