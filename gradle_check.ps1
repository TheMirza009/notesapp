param(
    [Parameter(Mandatory = $true)]
    [string]$GradleZipName
)

# Extract Gradle version (e.g. gradle-8.11.1-all.zip -> 8.11.1)
if ($GradleZipName -match "gradle-(\d+\.\d+(\.\d+)?)-") {
    $gradleVersion = $Matches[1]
} else {
    Write-Host "❌ Could not extract Gradle version from input. Example: gradle-8.11.1-all.zip"
    exit 1
}

# Compatibility table
$compatTable = @(
    @{ Gradle="8.13"; AGP="8.13"; Kotlin="2.1.20" },
    @{ Gradle="8.12"; AGP="8.12"; Kotlin="2.0.21" },
    @{ Gradle="8.11"; AGP="8.11"; Kotlin="2.0.20" },
    @{ Gradle="8.10"; AGP="8.10"; Kotlin="1.9.24" },
    @{ Gradle="8.9";  AGP="8.9";  Kotlin="1.9.23" },
    @{ Gradle="8.8";  AGP="8.8";  Kotlin="1.9.22" },
    @{ Gradle="8.7";  AGP="8.7";  Kotlin="1.9.21" },
    @{ Gradle="8.6";  AGP="8.6";  Kotlin="1.9.20" },
    @{ Gradle="8.5";  AGP="8.5";  Kotlin="1.9.20" },
    @{ Gradle="8.4";  AGP="8.4";  Kotlin="1.9.10" },
    @{ Gradle="8.3";  AGP="8.3";  Kotlin="1.9.0" },
    @{ Gradle="8.2";  AGP="8.2";  Kotlin="1.8.20" },
    @{ Gradle="8.1";  AGP="8.1";  Kotlin="1.8.10" },
    @{ Gradle="8.0";  AGP="8.0";  Kotlin="1.8.10" }
)

# Try to find the matching row
$match = $compatTable | Where-Object { $_.Gradle -eq $gradleVersion }

if ($null -eq $match) {
    Write-Host "⚠️  No exact match found for Gradle version $gradleVersion."
    Write-Host "    Using nearest lower version..."
    $numericInput = [version]$gradleVersion
    $sorted = $compatTable | Sort-Object { [version]$_.Gradle } -Descending
    foreach ($entry in $sorted) {
        if ([version]$entry.Gradle -le $numericInput) {
            $match = $entry
            break
        }
    }

    if ($null -eq $match) {
        Write-Host "❌ No compatible AGP/Kotlin mapping found for Gradle $gradleVersion"
        exit 1
    }
}

Write-Host "✅ Recommended Versions for Flutter (based on Gradle $gradleVersion):"
Write-Host "------------------------------------------------------------"
Write-Host "Gradle Version : $($match.Gradle)"
Write-Host "AGP (Plugin)   : $($match.AGP)"
Write-Host "Kotlin Version : $($match.Kotlin)"
Write-Host "------------------------------------------------------------"
Write-Host "💡 Tip: Update 'build.gradle(.kts)' and 'gradle-wrapper.properties' accordingly."
