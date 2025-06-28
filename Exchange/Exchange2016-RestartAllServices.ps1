<#
.SYNOPSIS
Redémarre de manière forcée tous les services essentiels pour Exchange 2016, y compris IIS.
Script amélioré pour garantir un redémarrage effectif et sécurisé.

Créé par espritdunet (Olivier Maréchal)

THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

Version 1.1, 2025-06-28

.DESCRIPTION
Ce script effectue les actions suivantes :
1. Vérifie qu'il est exécuté avec des privilèges d'administrateur.
2. Pour les services définis comme 'automatiques', il configure leur démarrage sur 'Automatic' et les redémarre de manière forcée.
3. Pour les services 'manuels', il configure leur démarrage sur 'Manual' et les redémarre uniquement s'ils étaient déjà en cours d'exécution.
4. Inclut les services critiques comme IIS (W3SVC, IISADMIN) qui sont nécessaires au bon fonctionnement d'Exchange.
5. Journalise chaque action pour un suivi clair.

.EXAMPLE
Exécutez le script dans une console PowerShell avec des droits d'administrateur sur le serveur Exchange.
.\Exchange2016-RestartAllServices.ps1
#>

# --- Vérification des privilèges ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Accès refusé. Ce script doit être exécuté avec des privilèges d'administrateur pour modifier les services."
    # Attend que l'utilisateur appuie sur une touche pour fermer, pour qu'il puisse lire le message.
    Read-Host "Appuyez sur Entrée pour quitter."
    exit 1
}

# --- Listes des services ---

# Services à configurer en démarrage Automatique et à redémarrer.
# W3SVC et IISADMIN (IIS) sont inclus car ils sont critiques pour OWA, ECP et les services web Exchange.
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

# Services à configurer en démarrage Manuel. Seront redémarrés uniquement s'ils sont en cours d'exécution.
$manualServices = @(
    "MSExchangePop3",
    "MSExchangePOP3BE",
    "wsbexchange",
    "AppIDSvc", # Ce service peut nécessiter des droits spécifiques.
    "pla"
)

# --- Fonction de journalisation ---

function Log-Message {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$type] $message"
}

# --- Exécution Principale ---

Log-Message "Début du script de redémarrage des services Exchange."

# Configure et redémarre les services automatiques
Log-Message "--- Traitement des services automatiques ---"
foreach ($service in $autoServices) {
    try {
        # S'assure que le service est configuré en automatique
        Set-Service -Name $service -StartupType Automatic -ErrorAction Stop
        Log-Message "Service $service configuré en démarrage Automatique."

        # Redémarre le service
        Restart-Service -Name $service -Force -ErrorAction Stop
        Log-Message "Service $service redémarré avec succès."
    } catch {
        Log-Message "Erreur lors du traitement du service $service: $_" "ERROR"
    }
}

# Configure et redémarre les services manuels si nécessaire
Log-Message "--- Traitement des services manuels ---"
foreach ($service in $manualServices) {
    try {
        # S'assure que le service est configuré en manuel
        Set-Service -Name $service -StartupType Manual -ErrorAction Stop
        Log-Message "Service $service configuré en démarrage Manuel."

        # Redémarre le service uniquement s'il était déjà en cours d'exécution
        $serviceStatus = (Get-Service -Name $service).Status
        if ($serviceStatus -eq 'Running') {
            Restart-Service -Name $service -Force -ErrorAction Stop
            Log-Message "Service $service (qui était en cours) a été redémarré."
        } else {
            Log-Message "Service $service n'est pas en cours d'exécution. Aucun redémarrage n'est effectué."
        }
    } catch {
        Log-Message "Erreur lors du traitement du service $service: $_" "ERROR"
    }
}

Log-Message "Script de redémarrage terminé."
