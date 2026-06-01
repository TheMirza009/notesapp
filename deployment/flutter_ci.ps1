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

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Set-StrictMode -Off

$script:REPO     = "TheMirza009/notesapp"
$script:APK_PATH = "build\app\outputs\flutter-apk\app-rc-release.apk"

Add-Type @"
using System; using System.IO;
public class ProgressStream : Stream {
    private readonly Stream _inner;
    private readonly long   _total;
    private long _read;
    public ProgressStream(Stream inner, long total) { _inner = inner; _total = total; }
    public override bool CanRead  => true;
    public override bool CanSeek  => false;
    public override bool CanWrite => false;
    public override long Length   => _total;
    public override long Position { get => _read; set => throw new NotSupportedException(); }
    public override int Read(byte[] buf, int off, int count) {
        int n = _inner.Read(buf, off, count); _read += n; return n;
    }
    public long BytesRead => _read;
    public long Total     => _total;
    public override void Flush() {}
    public override long Seek(long o, SeekOrigin r) => throw new NotSupportedException();
    public override void SetLength(long v)          => throw new NotSupportedException();
    public override void Write(byte[] b, int o, int c) => throw new NotSupportedException();
}
"@

# ─── UI helpers ───────────────────────────────────────────────────────────────

function _Write-Rule {
    Write-Host ("─" * 52) -ForegroundColor DarkGray
}

function _Write-Header([string]$Title, [string]$Sub = "") {
    Write-Host ""
    _Write-Rule
    if ($Sub) {
        Write-Host "  $Title  ·  $Sub" -ForegroundColor White
    } else {
        Write-Host "  $Title" -ForegroundColor White
    }
    _Write-Rule
    Write-Host ""
}

function _Write-Step([int]$N, [int]$Total, [string]$Label) {
    Write-Host ""
    Write-Host "  [$N/$Total] $Label" -ForegroundColor DarkCyan
}

function _Write-Ok([string]$Msg) {
    Write-Host "    ✓  $Msg" -ForegroundColor Green
}

function _Write-Skip([string]$Msg) {
    Write-Host "    ⊘  $Msg" -ForegroundColor DarkYellow
}

function _Write-Fail([string]$Msg) {
    Write-Host "    ✗  $Msg" -ForegroundColor Red
}

# Runs $Block on the main thread while a spinner animates on a background thread.
# Prints ✓ on success, ✗ + rethrows on failure.
function Invoke-WithSpinner {
    param([string]$Label, [scriptblock]$Block)

    $state = [hashtable]::Synchronized(@{ Done = $false })
    $lbl   = $Label

    $spinJob = Start-ThreadJob -ScriptBlock {
        param($s, $l)
        $frames = [string[]]@('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')
        $i = 0
        [Console]::ForegroundColor = [ConsoleColor]::DarkCyan
        while (-not $s.Done) {
            [Console]::Write("`r    $($frames[$i % $frames.Length])  $l  ")
            [System.Threading.Thread]::Sleep(80)
            $i++
        }
        [Console]::ResetColor()
    } -ArgumentList $state, $lbl

    $err = $null; $result = $null
    try   { $result = & $Block }
    catch { $err = $_ }

    $state.Done = $true
    $null = Wait-Job $spinJob
    Remove-Job $spinJob -Force

    if ($err) {
        [Console]::WriteLine("`r    ✗  $Label   ")
        throw $err
    }
    [Console]::ForegroundColor = [ConsoleColor]::Green
    [Console]::WriteLine("`r    ✓  $Label   ")
    [Console]::ResetColor()
    return $result
}

# Uploads a file to a URL with a live progress bar.
function _Invoke-UploadWithProgress {
    param([string]$Url, [string]$Token, [string]$FilePath, [double]$TotalMB)

    $barWidth = 28
    $fileStream = [System.IO.File]::OpenRead($FilePath)
    $progStream = [ProgressStream]::new($fileStream, $fileStream.Length)
    $content    = [System.Net.Http.StreamContent]::new($progStream)
    $content.Headers.ContentType   = [System.Net.Http.Headers.MediaTypeHeaderValue]::new(
        "application/vnd.android.package-archive")
    $content.Headers.ContentLength = $fileStream.Length

    $client = [System.Net.Http.HttpClient]::new()
    $client.Timeout = [System.TimeSpan]::FromMinutes(10)
    [void]$client.DefaultRequestHeaders.TryAddWithoutValidation("Authorization", "Bearer $Token")
    [void]$client.DefaultRequestHeaders.TryAddWithoutValidation("Accept", "application/vnd.github+json")

    $task = $client.PostAsync($Url, $content)

    while (-not $task.IsCompleted) {
        $bytes  = $progStream.BytesRead
        $total  = $progStream.Total
        $pct    = if ($total -gt 0) { $bytes / $total } else { 0 }
        $filled = [int]($barWidth * $pct)
        $bar    = ("█" * $filled) + ("░" * ($barWidth - $filled))
        $mb     = [math]::Round($bytes / 1MB, 1)
        [Console]::ForegroundColor = [ConsoleColor]::DarkCyan
        [Console]::Write("`r    [$bar]  $mb / $TotalMB MB  ")
        [Console]::ResetColor()
        Start-Sleep -Milliseconds 120
    }

    $fileStream.Dispose()
    $response = $task.GetAwaiter().GetResult()
    $client.Dispose()

    if (-not $response.IsSuccessStatusCode) {
        $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        [Console]::WriteLine("`r    ✗  Upload failed ($([int]$response.StatusCode))   ")
        throw "APK upload failed: $body"
    }

    [Console]::ForegroundColor = [ConsoleColor]::Green
    [Console]::WriteLine("`r    ✓  APK uploaded  ($TotalMB MB)   ")
    [Console]::ResetColor()
}

# ─────────────────────────────────────────────────────────────────────────────
# deploy-test
# Build RC APK → ADB install → git push → GitHub Pre-Release → email testers
# ─────────────────────────────────────────────────────────────────────────────
function deploy-test {
    Push-Location "d:\Android_Dev\Flutter\Projects\notesapp"
    try {

        # ── Header ────────────────────────────────────────────────────────────
        $branch  = git rev-parse --abbrev-ref HEAD
        $version = (Select-String "^version:" pubspec.yaml | ForEach-Object { $_.Line -replace "version:\s*", "" }).Trim()
        _Write-Header "deploy-test" "$version  ·  $branch"

        # ── [1/5] Build ───────────────────────────────────────────────────────
        _Write-Step 1 5 "Build"
        flutter build apk --release --flavor rc
        if ($LASTEXITCODE -ne 0) { _Write-Fail "Build failed"; return }
        $apkMB = [math]::Round((Get-Item $script:APK_PATH).Length / 1MB, 1)
        _Write-Ok "APK built  ($apkMB MB)"

        # ── [2/5] ADB Install ─────────────────────────────────────────────────
        _Write-Step 2 5 "ADB Install"
        $serials = adb devices 2>&1 |
            Where-Object { $_ -match "\bdevice$" } |
            ForEach-Object { ($_ -split "\s+")[0] }

        if (-not $serials) {
            _Write-Skip "No device connected"
        } elseif (@($serials).Count -eq 1) {
            Invoke-WithSpinner "Installing on $serials" {
                adb -s $serials install -r $script:APK_PATH | Out-Null
            }
        } else {
            Write-Host ""
            Write-Host "    Multiple devices connected:" -ForegroundColor Cyan
            $i = 1
            foreach ($s in $serials) { Write-Host "      [$i] $s"; $i++ }
            $pick   = Read-Host "    Select device number"
            $serial = @($serials)[[int]$pick - 1]
            Invoke-WithSpinner "Installing on $serial" {
                adb -s $serial install -r $script:APK_PATH | Out-Null
            }
        }

        # ── [3/5] Git ─────────────────────────────────────────────────────────
        _Write-Step 3 5 "Git"
        git add .
        Write-Host ""
        $commitMsg = Read-Host "    Commit message"
        if (-not $commitMsg) { _Write-Fail "Commit message cannot be empty"; return }

        $committed = $false
        git commit -m $commitMsg 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $committed = $true
            _Write-Ok "Committed: `"$commitMsg`""
        } else {
            _Write-Skip "Nothing to commit"
        }

        Invoke-WithSpinner "Pushing → $branch" {
            git push origin $branch 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) { _Write-Fail "Git push failed"; return }

        $sha     = git rev-parse --short HEAD
        $fullSha = git rev-parse HEAD

        # ── [4/5] GitHub Release ──────────────────────────────────────────────
        _Write-Step 4 5 "GitHub Release"
        $token = $env:GITHUB_TOKEN
        if (-not $token) { _Write-Skip "GITHUB_TOKEN not set — skipping"; return }

        $headers = @{
            Authorization  = "Bearer $token"
            "Content-Type" = "application/json"
            Accept         = "application/vnd.github+json"
        }
        $tagName = "test-$sha"

        Invoke-WithSpinner "Creating tag  ($tagName)" {
            try {
                $tagObj = @{ tag = $tagName; message = "Test build $sha"; object = $fullSha; type = "commit" } | ConvertTo-Json
                Invoke-RestMethod -Uri "https://api.github.com/repos/$script:REPO/git/tags" `
                    -Method Post -Headers $headers -Body $tagObj | Out-Null
            } catch {
                $sc = $null; try { $sc = $_.Exception.Response.StatusCode.value__ } catch {}
                if ($sc -ne 422) { throw }
            }
            try {
                $refObj = @{ ref = "refs/tags/$tagName"; sha = $fullSha } | ConvertTo-Json
                Invoke-RestMethod -Uri "https://api.github.com/repos/$script:REPO/git/refs" `
                    -Method Post -Headers $headers -Body $refObj | Out-Null
            } catch {
                $sc = $null; try { $sc = $_.Exception.Response.StatusCode.value__ } catch {}
                if ($sc -ne 422) { throw }
            }
        }

        $release = Invoke-WithSpinner "Creating release" {
            $releaseObj = @{
                tag_name   = $tagName
                name       = "Test Build $sha"
                body       = "Commit: $fullSha`nBranch: $branch"
                prerelease = $true
                draft      = $false
            } | ConvertTo-Json
            try {
                Invoke-RestMethod -Uri "https://api.github.com/repos/$script:REPO/releases" `
                    -Method Post -Headers $headers -Body $releaseObj
            } catch {
                $sc = $null; try { $sc = $_.Exception.Response.StatusCode.value__ } catch {}
                if ($sc -ne 422) { throw }
                # Release already exists — fetch it
                Invoke-RestMethod -Uri "https://api.github.com/repos/$script:REPO/releases/tags/$tagName" `
                    -Headers $headers
            }
        }

        $uploadUrl = $release.upload_url -replace '\{.*\}', ''
        _Invoke-UploadWithProgress `
            -Url     "${uploadUrl}?name=notesapp-rc-${sha}.apk" `
            -Token   $token `
            -FilePath (Resolve-Path $script:APK_PATH).Path `
            -TotalMB  $apkMB

        $releaseUrl = $release.html_url
        Write-Host ""
        Write-Host "    → $releaseUrl" -ForegroundColor DarkCyan

        # ── [5/5] Email ───────────────────────────────────────────────────────
        _Write-Step 5 5 "Email"
        _Send-TestEmail -Sha $sha -FullSha $fullSha -Branch $branch -ReleaseUrl $releaseUrl

        # ── Done ──────────────────────────────────────────────────────────────
        Write-Host ""
        _Write-Rule
        Write-Host "  ✓  deploy-test complete" -ForegroundColor Green
        _Write-Rule
        Write-Host ""

    } finally {
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

        $sha     = git rev-parse --short HEAD
        $lastMsg = git log -1 --pretty=%s
        $branch  = git rev-parse --abbrev-ref HEAD

        # ── Warning ───────────────────────────────────────────────────────────
        Write-Host ""
        Write-Host ("═" * 52) -ForegroundColor Yellow
        Write-Host "  ⚠   PRODUCTION DEPLOYMENT" -ForegroundColor Red
        Write-Host ("═" * 52) -ForegroundColor Yellow
        Write-Host "  Commit  :  $sha — $lastMsg" -ForegroundColor White
        Write-Host "  Branch  :  $branch" -ForegroundColor White
        Write-Host "  This will go LIVE for ALL users." -ForegroundColor Red
        Write-Host ("═" * 52) -ForegroundColor Yellow
        Write-Host ""

        $confirm = Read-Host "  Type 'yes' to continue"
        if ($confirm -ne "yes") { Write-Host "`n  Cancelled." -ForegroundColor DarkYellow; return }

        # ── Release notes ─────────────────────────────────────────────────────
        Write-Host ""
        Write-Host "  Enter release notes (blank line to finish):" -ForegroundColor Cyan
        $lines = @()
        while ($true) {
            $line = Read-Host "  >"
            if ($line -eq "") { break }
            $lines += $line
        }
        $releaseNotes = $lines -join "`n"
        if (-not $releaseNotes) { _Write-Fail "Release notes cannot be empty"; return }

        # ── [1/2] Git push ────────────────────────────────────────────────────
        _Write-Step 1 2 "Git"
        Invoke-WithSpinner "Pushing → $branch" {
            git push origin $branch 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -ne 0) { _Write-Fail "Git push failed. Aborting."; return }

        # ── [2/2] Trigger workflow ────────────────────────────────────────────
        _Write-Step 2 2 "GitHub Actions"
        $token = $env:GITHUB_TOKEN
        if (-not $token) { _Write-Fail "GITHUB_TOKEN not set"; return }

        Invoke-WithSpinner "Triggering deploy_prod workflow" {
            $body = @{
                ref    = "main"
                inputs = @{ release_notes = $releaseNotes }
            } | ConvertTo-Json
            Invoke-RestMethod `
                -Uri "https://api.github.com/repos/$script:REPO/actions/workflows/deploy_prod.yml/dispatches" `
                -Method Post `
                -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json"; Accept = "application/vnd.github+json" } `
                -Body $body | Out-Null
        }

        Write-Host ""
        Write-Host "    → https://github.com/$script:REPO/actions" -ForegroundColor DarkCyan

        Write-Host ""
        _Write-Rule
        Write-Host "  ✓  deploy-prod triggered — monitor GitHub Actions for progress" -ForegroundColor Green
        _Write-Rule
        Write-Host ""

    } finally {
        Pop-Location
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Internal — send test build email via SMTP
# ─────────────────────────────────────────────────────────────────────────────
function _Send-TestEmail {
    param($Sha, $FullSha, $Branch, $ReleaseUrl)

    $mailUser   = $env:MAIL_USERNAME
    $mailPass   = $env:MAIL_APP_PASSWORD
    $recipients = $env:TESTER_EMAILS

    if (-not $mailUser -or -not $mailPass -or -not $recipients) {
        _Write-Skip "Email env vars not set — skipping"
        return
    }

    $count = ($recipients -split ',').Count
    Invoke-WithSpinner "Sending to $count recipient$(if($count -ne 1){'s'})" {
        $smtp             = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
        $smtp.EnableSsl   = $true
        $smtp.Credentials = New-Object System.Net.NetworkCredential($mailUser, $mailPass)
        $msg              = New-Object System.Net.Mail.MailMessage
        $msg.From         = $mailUser
        $msg.Subject      = "✅ Test Build Ready — $Sha"
        $msg.Body         = "A new test build is ready.`n`nCommit  : $FullSha`nBranch  : $Branch`n`nDownload : $ReleaseUrl"
        $msg.IsBodyHtml   = $false
        foreach ($addr in ($recipients -split ',')) {
            $t = $addr.Trim(); if ($t) { $msg.To.Add($t) }
        }
        try   { $smtp.Send($msg) }
        finally { $msg.Dispose(); $smtp.Dispose() }
    }
}
