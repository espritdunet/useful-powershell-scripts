<#
.SYNOPSIS
    Recursively compares two directories and generates a report of discrepancies between the source and target directories.

    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE  
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

    Version 1.0, 2024-04-02

    Please submit ideas, comments, and suggestions using GitHub. 

.DESCRIPTION
    This script compares the contents of two directories (including subdirectories) and generates a report detailing missing, differing, and additional files and directories. 
    It calculates the SHA256 hash of files to detect differences in content.

.AUTHOR
    espritdunet (Olivier Maréchal)

.PARAMETER SourceDir
    The path to the source directory.

.PARAMETER TargetDir
    The path to the target directory.

.PARAMETER ReportFile
    The path to the output report file.

.EXAMPLE
    Compare-DirectoriesRecursive.ps1 -SourceDir "C:\Path\To\Source" -TargetDir "D:\Path\To\Target" -ReportFile "C:\Path\To\Report\DiscrepanciesReport.txt"
#>

param (
    [string]$SourceDir = "X:\Path\To\Source",
    [string]$TargetDir = "Y:\Path\To\Target",
    [string]$ReportFile = "C:\Path\To\Report\DiscrepanciesReport.txt"
)

# Function to compare directories
function Compare-Directories {
    param (
        [string]$source,
        [string]$target,
        [ref]$report
    )

    # Get files and directories in the source directory
    $sourceItems = Get-ChildItem -Path $source -Recurse

    # Get files and directories in the target directory
    $targetItems = Get-ChildItem -Path $target -Recurse

    # Compare source and target items
    foreach ($sourceItem in $sourceItems) {
        $relativePath = $sourceItem.FullName.Substring($source.Length)
        $targetItem = $target + $relativePath

        if (-not (Test-Path -Path $targetItem)) {
            $report.Value += "MISSING: $targetItem`r`n"
        } elseif ($sourceItem.PSIsContainer -eq $false) {
            $sourceHash = Get-FileHash -Path $sourceItem.FullName -Algorithm SHA256
            $targetHash = Get-FileHash -Path $targetItem -Algorithm SHA256

            if ($sourceHash.Hash -ne $targetHash.Hash) {
                $report.Value += "DIFFERENT: $targetItem`r`n"
            }
        }
    }

    foreach ($targetItem in $targetItems) {
        $relativePath = $targetItem.FullName.Substring($target.Length)
        $sourceItem = $source + $relativePath

        if (-not (Test-Path -Path $sourceItem)) {
            $report.Value += "ADDITIONAL: $sourceItem`r`n"
        }
    }
}

# Initialize the report
$reportContent = ""

# Call the function to compare directories
Compare-Directories -source $SourceDir -target $TargetDir -report ([ref]$reportContent)

# Write the report to a file
Set-Content -Path $ReportFile -Value $reportContent

Write-Host "Comparison complete. Report saved to $ReportFile"
