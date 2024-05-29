<# 
    .SYNOPSIS 
    Move mailboxes and archives smaller than a specified size limit with error handling and cleanup of completed move requests.

    Created by espritdunet (Olivier Maréchal)

    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE  
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

    Version 1.0, 2024-04-02

    .DESCRIPTION 
    This script moves mailboxes and their archives that are smaller than a specified size limit to target databases. 
    It handles errors and cleans up completed move requests before creating new move requests.

    .PARAMETER TargetDatabase  
    The target mailbox database.

    .PARAMETER ArchiveTargetDatabase
    The target archive database.

    .PARAMETER SizeLimitGB
    The size limit for the migration in gigabytes.

    .EXAMPLE 
    Move mailboxes and archives smaller than 0.2 GB to the target databases named DB01 for mailboxes and ARCHIVES-DATABASE for archives.
    .\Move-MailboxesBySize.ps1 -TargetDatabase "DB01" -ArchiveTargetDatabase "ARCHIVES-DATABASE" -SizeLimitGB 0.2
#>

param (
    [parameter(Mandatory, HelpMessage = 'The target mailbox database')]
    [string]$TargetDatabase = "DB01",

    [parameter(Mandatory, HelpMessage = 'The target archive database')]
    [string]$ArchiveTargetDatabase = "ARCHIVES-DATABASE",

    [parameter(Mandatory, HelpMessage = 'The size limit for the migration in gigabytes')]
    [decimal]$SizeLimitGB = 0.2
)

# Fetch all mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited

foreach ($mailbox in $mailboxes) {
    try {
        # Get mailbox statistics
        $mailboxStats = Get-MailboxStatistics -Identity $mailbox.Identity
        $archiveStats = $null
        $totalSizeGB = $mailboxStats.TotalItemSize.Value.ToBytes() / 1GB

        # Check if an archive exists and add its size
        if ($mailbox.ArchiveGuid -ne [Guid]::Empty) {
            $archiveStats = Get-MailboxStatistics -Identity $mailbox.Identity -Archive
            $totalSizeGB += $archiveStats.TotalItemSize.Value.ToBytes() / 1GB
        }

        # Check if the total size is less than the specified size limit and if the current database is not already the target database
        if ($totalSizeGB -lt $SizeLimitGB -and $mailbox.Database -ne $TargetDatabase -and $mailbox.ArchiveDatabase -ne $ArchiveTargetDatabase) {
            # Check for an existing completed move request and remove it if necessary
            $existingMoveRequest = Get-MoveRequest -Identity $mailbox.Identity -ErrorAction SilentlyContinue
            if ($existingMoveRequest -and $existingMoveRequest.Status -eq "Completed") {
                Remove-MoveRequest -Identity $mailbox.Identity
                Write-Host "Previous move request for $($mailbox.DisplayName) removed."
            }

            # Create a new move request for the mailbox and the archive
            New-MoveRequest -Identity $mailbox.Identity -TargetDatabase $TargetDatabase -ArchiveTargetDatabase $ArchiveTargetDatabase
            Write-Host "Move request for mailbox $($mailbox.DisplayName) to $TargetDatabase and $ArchiveTargetDatabase created successfully."
        } elseif ($mailbox.Database -eq $TargetDatabase -or $mailbox.ArchiveDatabase -eq $ArchiveTargetDatabase) {
            Write-Host "Mailbox $($mailbox.DisplayName) is already on the target database."
        }
    } catch {
        Write-Host "Error moving mailbox $($mailbox.DisplayName): $_"
    }
}
