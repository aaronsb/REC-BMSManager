#
# Module manifest for module 'REC-BMSManager'
#
# Generated by: Aaron Bockelie
#
# Generated on: 6/2/2020
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'REC-BMSManager.psm1'

# Version number of this module.
ModuleVersion = '0.9.5'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'b21ecfb8-30ee-45fc-a645-b16c91ba4df6'

# Author of this module
Author = 'Aaron Bockelie'

# Company or vendor of this module
CompanyName = 'AaronBockelie'

# Copyright statement for this module
Copyright = '(c) Aaron Bockelie. All rights reserved.'

# Description of the functionality provided by this module
# Description = ''

# Minimum version of the PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    "Get-BMSParameter",
    "Set-BMSParameter",
    "Get-BMSInstructionList",
    "Get-BMSLibraryInstance",
    "Send-MQTTValue",
    "Install-BMSMQTTService",
    "Uninstall-BMSMQTTService",
    "Repair-BMSMQttService"
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# PrivateData is where all third-party metadata goes
PrivateData            = @{
    # PrivateData.PSData is the PowerShell Gallery data
    PSData             = @{
        # Prerelease string should be here, so we can set it
        Prerelease     = 'beta'

        # Release Notes have to be here, so we can update them
        ReleaseNotes   = 'Semi-functional release'

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags           = 'REC-BMS','Battery','Instrumentation','Management'

        # A URL to the license for this module.
        LicenseUri     = 'https://github.com/aaronsb/ps-recbms/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri     = 'https://github.com/aaronsb/ps-recbms'

        # A URL to an icon representing this module.
        IconUri        = 'https://github.com/aaronsb/ps-recbms/raw/master/images/rec-logo.png'
    } # End of PSData
} # End of PrivateData

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

