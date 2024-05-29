<# 
    .SYNOPSIS 
    Restart all services on an Exchange 2016 server.

    Created by espritdunet (Olivier Maréchal)

    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE  
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 

    Version 1.0, 2024-04-02

    .DESCRIPTION 
    This script sets the startup type and restarts all Exchange services on a server. 
    It handles both automatic and manual services, with error handling and logging.

    .PARAMETER AutoServices  
    List of services to set to Automatic startup and restart.

    .PARAMETER ManualServices
    List of services to set to Manual startup and restart if they are running.

    .EXAMPLE 
    Restart all Exchange services on the server.
    .\Restart-ExchangeServices.ps1
#>

# List of Exchange services to set to Automatic startup and restart
$autoServices = @(
    "MSExchangeADTopology",
    "MSExchangeAntispamUpdate",
    "MSExchangeDagMgmt",
    "MSExchangeDiagnostics",
    "MSExchangeEdgeSync",
    "MSExchangeFrontEndTransport",
    "MSExchangeHM",
    "MSExchangeImap4",
    "MSExchangeIMAP4BE",
    "MSExchangeIS",
    "MSExchangeMailboxAssistants",
    "MSExchangeMailboxReplication",
    "MSExchangeDelivery",
    "MSExchangeSubmission",
    "MSExchangeRepl",
    "MSExchangeRPC",
    "MSExchangeFastSearch",
    "HostControllerService",
    "MSExchangeServiceHost",
    "MSExchangeThrottling",
    "MSExchangeTransport",
    "MSExchangeTransportLogSearch",
    "MSExchangeUM",
    "MSExchangeUMCR",
    "FMS",
    "IISADMIN",
    "RemoteRegistry",
    "SearchExchangeTracing",
    "Winmgmt",
    "W3SVC"
)

# List of services to set to Manual startup and restart if they are running
$manualServices = @(
    "MSExchangePop3",
    "MSExchangePOP3BE",
    "wsbexchange",
    "AppIDSvc", # This service might require specific administrative rights to be modified.
    "pla"
)

# Function to log messages
function Log-Message {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$type] $message"
}

# Configure and restart automatic services
foreach ($service in $autoServices) {
    try {
        Set-Service -Name $service -StartupType Automatic -ErrorAction Stop
        $serviceStatus = (Get-Service -Name $service).Status
        if ($serviceStatus -ne 'Running') {
            Restart-Service -Name $service -Force -ErrorAction Stop
            Log-Message "Service $service set to start automatically and restarted."
        } else {
            Log-Message "Service $service is already running. No need to restart."
        }
    } catch {
        Log-Message "Error configuring or restarting service $service: $_" "ERROR"
    }
}

# Configure and restart manual services if necessary
foreach ($service in $manualServices) {
    try {
        Set-Service -Name $service -StartupType Manual -ErrorAction Stop
        $serviceStatus = (Get-Service -Name $service).Status
        if ($serviceStatus -eq 'Running') {
            Restart-Service -Name $service -Force -ErrorAction Stop
            Log-Message "Service $service set to start manually and restarted."
        } else {
            Log-Message "Service $service set to start manually. No restart needed as it is not running."
        }
    } catch {
        Log-Message "Error configuring or restarting service $service: $_" "ERROR"
    }
}
