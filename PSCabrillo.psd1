<#
    PSCabrillo.psd1, module manifest for the PSCabrillo module
    Copyright (C) 2020 Colin Cogle, KC1HBK <colin@colincogle.name>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSCabrillo.psm1'

# Version number of this module.
ModuleVersion = '0.0.1'

# Supported PSEditions
CompatiblePSEditions = @("Core", "Desktop")

# ID used to uniquely identify this module
GUID = '43c6528d-18af-4ae0-9c71-3d46b211d7b6'

# Author of this module
Author = 'Colin Cogle'

# Copyright statement for this module
Copyright = '(c) 2020 Colin Cogle. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Converts Cabrillo 3.0 logs into PowerShell objects.'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.0'

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @("ConvertFrom-Cabrillo")

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = ''

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
DscResourcesToExport = @()

# List of all modules packaged with this module
ModuleList = @()

# List of all files packaged with this module
FileList = @(
    "AUTHORS",
    "CHANGELOG",
    "LICENSE",
    "NEWS",
    "README.md",
    "tests/cqwwrtty.com-sample.cbr3",
    "PSCabrillo.psd1",
    "PSCabrillo.psm1"
)

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("amateur radio", "Cabrillo", "contact", "contest", "DX",
                 "Field Day", "ham radio", "logs", "QSO", "radio")

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/rhymeswithmogul/PSCabrillo/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/rhymeswithmogul/PSCabrillo'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'https://github.com/rhymeswithmogul/PSCabrillo/blob/master/CHANGELOG'

        # Prerelease string of this module
        Prerelease = 'alpha'

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        RequireLicenseAcceptance = $false

        # External dependent modules of this module
        ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

