<#
    PSCabrillo.psm1, root module for the PSCabrillo module
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

#Requires -Version 7.0

Function ConvertFrom-Cabrillo {
    [CmdletBinding(DefaultParameterSetName = "FromStrings")]
    [OutputType([PSCabrillo.CabrilloLog])]

    Param(
        [Parameter(
            ParameterSetName = "FromStrings",
            HelpMessage = "Enter some Cabrillo data",
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromRemainingArguments)]
        [Alias("InputObject")]
        [System.String[][]] $CabrilloData,

        [Parameter(
            ParameterSetName = "FromFile",
            HelpMessage = "Enter one or more filenames",
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            ValueFromRemainingArguments)]
        [Alias("Path")]
        [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
        [System.IO.File] $CabrilloFile,

        [Switch] $NoTransmitterIDCheck
    )

    Begin
    {
        # Create our return object, with a place to store QSO's.
        $CabrilloObject = [PSCustomObject]@{
            "QSO" = @()
        }

        If ($PSCmdlet.ParameterSetName -eq "FromFile") {
            $CabrilloData = Get-Content -Path $CabrilloFile
        }

        # This variable is only to make sure that the first line contains the
        # proper START-OF-LOG tag.  It's also used for debug stream output.
        $line = 0
    }

    Process
    {
        $KeyValuePair = $_ -Split ": "
        Write-Debug -Message "Line $($line + 1): Tag=`"$($KeyValuePair[0])`", Value=`"$($KeyValuePair[1])`""

        # Check for the required first line.
        If ($line -eq 0) {
            If ($KeyValuePair[0] -ne "START-OF-LOG")
            {
                Throw [System.IO.InvalidDataException]::new("This Cabrillo file is not well-formed.  Expected on line 1: START-OF-LOG")
            }
            ElseIf ($KeyValuePair[1] -ne "3.0")
            {
                Throw [System.NotImplementedException]::new("This module can only parse Cabrillo 3.0 log files.")
            }
            Else
            {
                $MemberProperties = @{
                    "NotePropertyName"  = "Version"
                    "NotePropertyValue" = [System.Version]::new($KeyValuePair[1])
                }
                Add-Member -InputObject $CabrilloObject @MemberProperties
                Write-Verbose "Found a version $($KeyValuePair[1]) Cabrillo log."
            }
        }

        # Check for the required last line.
        ElseIf ($line -eq $CabrilloData.Count - 1)
        {
            If ($KeyValuePair[0] -ne "END-OF-LOG")
            {
                Throw [System.IO.InvalidDataException]::new("This Cabrillo file is not well-formed.  Expected on $($line + 1): END-OF-LOG")
            }
        }

        # Parse all other tags.
        Else
        {
            Switch -RegEx ($keyValuePair[0])
            {
                "CALLSIGN"
                {
                    Write-Verbose "The callsign used during the contest was $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "CallSign"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CONTEST"
                {
                    Write-Verbose "This contest was $($KeyValuePair[1])."
                    If ($KeyValuePair[1] -NotMatch [RegEx]::"[A-Z0-9\-]+")
                    {
                        Throw [System.IO.InvalidDataException]::new("The contest value is invalid.")
                    }
                    $MemberProperties = @{
                        "NotePropertyName"  = "Contest"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-ASSISTED"
                {
                    Write-Verbose "This category was $($KeyValuePair[1])."
                    If ($KeyValuePair[1] -NotMatch [RegEx]::"(NON\-)?ASSISTED")
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-ASSISTED was not an acceptable value.")
                    }
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryAssisted"
                        "NotePropertyValue" = $KeyValuePair[1] -eq "ASSISTED"
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-BAND"
                {
                    New-Variable -Option Constant -Name "AcceptableBands" -Value `
                        @("ALL", "160M", "80M", "40M", "20M", "15M", "10M",
                        "6M", "4M", "2M", "222", "432", "902", "1.2G", "2.3G",
                        "3.4G", "5.7G", "10G", "24G", "47G", "75G", "123G",
                        "134G", "241G", "Light", "VHF-3-BAND", "VHF-FM-ONLY")

                    Write-Verbose "The band is $($KeyValuePair[1])."
                    If ($KeyValuePair[1] -NotIn $AcceptableBands)
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-BAND was not an accepted value.")
                    }
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryBand"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-MODE"
                {
                    Write-Verbose "The mode is $($KeyValuePair[1])."
                    If ($KeyValuePair[1] -NotIn @("CW",  "DIGI", "FM", "RTTY",
                                                "SSB", "MIXED"))
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-MODE was not an accepted mode.")
                    }
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryMode"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-OPERATOR"
                {
                    If ($KeyValuePair[1] -NotIn @("SINGLE-OP", "MULTI-OP", "CHECKLOG"))
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-OPERATOR was not an accepted operator.")
                    }
                    Write-Verbose "The mode is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryOperator"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-POWER"
                {
                    If ($KeyValuePair[1] -NotIn @("HIGH", "LOW", "QRP"))
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-POWER was not an accepted operator.")
                    }
                    Write-Verbose "The power is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryPower"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-STATION"
                {
                    New-Variable -Option Constant -Name "AcceptableStations" `
                        -Value @("FIXED", "MOBILE", "PORTABLE", "ROVER", "HQ",
                                "ROVER-LIMITED", "ROVER-UNLIMITED", "SCHOOL",
                                "EXPEDITION")
                    If ($KeyValuePair[1] -NotIn $AcceptableStations)
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-STATION was not an accepted type.")
                    }
                    Write-Verbose "The station type is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryStation"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-TIME"
                {
                    If ($KeyValuePair[1] -NotMatch "[6,12,24]\-HOURS")
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-TIME was not an accepted period.")
                    }
                    Write-Verbose "The period is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryTime"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-TRANSMITTER"
                {
                    If ($KeyValuePair[1] -NotIn @("ONE", "TWO", "LIMITED",
                                                "UNLIMITED", "SWL"))
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-TRANSMITTER was not an accepted value.")
                    }
                    Write-Verbose "The transmitter type is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryTransmitter"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CATEGORY-OVERLAY"
                {
                    If ($KeyValuePair[1] -NotIn @("CLASSIC", "ROOKIE", "OVER-50",
                                                "TB-WIRES", "NOVICE-TECH"))
                    {
                        Throw [System.IO.InvalidDataException]::new("The value for CATEGORY-OVERLAY was not an accepted overlay.")
                    }
                    Write-Verbose "The overlay is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "CategoryOverlay"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CERTIFICATE"
                {
                    If ($KeyValuePair[1] -NotIn @("YES", "NO")) {
                        Throw [System.IO.InvalidDataException]::new("A CERTIFICATE tag was found with an invalid value!")
                    }

                    Write-Verbose "Found a certificate tag: $($KeyValuePair[1])"
                    $MemberProperties = @{
                        "NotePropertyName"  = "Certificate"
                        "NotePropertyValue" = $KeyValuePair[1] -eq "YES"
                    }
                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CLAIMED-SCORE"
                {
                    Write-Verbose "The claimed score is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "ClaimedScore"
                        "NotePropertyValue" = $KeyValuePair[1] -As [int]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CLUB"
                {
                    Write-Verbose "The club name is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "Club"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "CREATED-BY"
                {
                    Write-Verbose "The logging software name and version is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "CreatedBy"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "EMAIL"
                {
                    # TODO: Make sure it's a valid email, or $null.
                    Write-Verbose "The entrant's email is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "Email"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }
                
                "GRID-LOCATOR"
                {
                    If ($KeyValuePair[1] -NotMatch [regex]"[A-Za-z]{2}[0-9]{2}[A-Za-z]{2}")
                    {
                        Throw [System.IO.InvalidDataException]::new("The grid square $($KeyValuePair[1]) is invalid!")
                    }

                    Write-Verbose "The Maidenhead grid square is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "GridLocator"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }        

                "LOCATION"
                {
                    # There are too many possible locations to list, but if it's
                    # possible to create a regex or -(Not)In match for it, then
                    # I welcome the addition!
                    Write-Verbose "The operating location is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "Location"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "NAME"
                {
                    If ($KeyValuePair[1].Length -gt 75) {
                        Throw [System.IO.InvalidDataException]::new("The operator's name cannot exceed 75 characters!")
                    }

                    Write-Verbose "The operator's name is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "Name"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "ADDRESS"
                {
                    If ($KeyValuePair[1].Length -gt 45) {
                        Throw [System.IO.InvalidDataException]::new("Address lines cannot exceed 45 characters!")
                    }

                    Write-Verbose "A mailing address line is $($KeyValuePair[1])."

                    If ($null -eq $CabrilloObject.Address)
                    {
                        $MemberProperties = @{
                            "NotePropertyName" = "Address"
                            "NotePropertyValue" = $KeyValuePair[1]
                        }
                        Add-Member -InputObject $CabrilloObject @MemberProperties
                    }
                    Else
                    {
                        $CabrilloObject.Address += "`n$($KeyValuePair[1])"
                    }
                }

                "ADDRESS-CITY"
                {
                    If ($KeyValuePair[1].Length -gt 45) {
                        Throw [System.IO.InvalidDataException]::new("Address lines cannot exceed 45 characters!")
                    }

                    Write-Verbose "The mailing address's city is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "AddressCity"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "ADDRESS-STATE-PROVINCE"
                {
                    If ($KeyValuePair[1].Length -gt 45) {
                        Throw [System.IO.InvalidDataException]::new("Address lines cannot exceed 45 characters!")
                    }

                    Write-Verbose "The mailing address's state/province is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "AddressStateProvince"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties

                    $MemberProperties = @{
                        "Type"  = "AliasProperty"
                        "Value" = "AddressStateProvince"
                    }

                    If ($null -eq $CabrilloObject.AddressState)
                    {
                        Add-Member -InputObject $CabrilloObject @MemberProperties -Name "AddressState"
                    }
                    If ($null -eq $CabrilloObject.AddressProvince)
                    {
                        Add-Member -InputObject $CabrilloObject @MemberProperties -Name "AddressProvince"
                    }

                }

                "ADDRESS-POSTALCODE"
                {
                    If ($KeyValuePair[1].Length -gt 45) {
                        Throw [System.IO.InvalidDataException]::new("Address lines cannot exceed 45 characters!")
                    }

                    Write-Verbose "The mailing address's postal code is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "AddressPostalCode"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "ADDRESS-COUNTRY"
                {
                    If ($KeyValuePair[1].Length -gt 45) {
                        Throw [System.IO.InvalidDataException]::new("Address lines cannot exceed 45 characters!")
                    }

                    Write-Verbose "The mailing address's country is $($KeyValuePair[1])."
                    $MemberProperties = @{
                        "NotePropertyName"  = "AddressCountry"
                        "NotePropertyValue" = $KeyValuePair[1]
                    }

                    Add-Member -InputObject $CabrilloObject @MemberProperties
                }

                "OPERATORS"
                {
                    If ($KeyValuePair[1].Length -gt 75) {
                        Throw [System.IO.InvalidDataException]::new("Operator lines cannot exceed 75 characters!")
                    }

                    Write-Verbose "Found an operator line: $($KeyValuePair[1])"

                    If ($null -eq $Cabrillo.Operators)
                    {
                        Add-Member -InputObject $CabrilloObject -NotePropertyName "Operators" -NotePropertyValue @()
                    }

                    $KeyValuePair[1] -Split [RegEx]"[\s,]+" | ForEach-Object {
                        Write-Verbose " - Found an operator: $_"
                        $CabrilloObject.Operators += $_
                    }
                }

                "OFFTIME"
                {
                    If ($KeyValuePair[1] -NotMatch "(?:\d{4}-[01]\d-[0-3]\d [012]\d{3}\s?){2}") {
                        Throw [System.IO.InvalidDataException]::new("This does not appear to be a well-formed OFFTIME.")
                    }

                    Write-Verbose "Found an offtime: $($KeyValuePair[1])"
                    If ($null -eq $Cabrillo.OffTimes)
                    {
                        Add-Member -InputObject $CabrilloObject -NotePropertyName "OffTimes" -NotePropertyValue @()
                    }

                    $Times = -Split $KeyValuePair[1]
                    $CabrilloObject.OffTimes += [ordered]@{
                        "Start" = (Get-Date -Date "${$Times[0]}Z")
                        "End"   = (Get-Date -Date "${$Times[1]}Z")
                    }


                }

                "SOAPBOX"
                {
                    If ($KeyValuePair[1].Length -gt 75) {
                        Throw [System.IO.InvalidDataException]::new("A SOAPBOX comment cannot exceed 75 characters!")
                    }

                    Write-Verbose "Found a comment: $($KeyValuePair[1])"
                    If ($null -eq $CabrilloObject.Soapboxes)
                    {
                        Add-Member -InputObject $CabrilloObject -NotePropertyName "Soapboxes" -NotePropertyValue @()
                        Add-Member -InputObject $CabrilloObject -Type AliasProperty -Name "Comments" -Value "Soapboxes"
                    }

                    $CabrilloObject.Soapboxes += $KeyValuePair[1]
                }

                "(?:X-)?QSO"
                {
                    Write-Verbose "Found a QSO line: $($KeyValuePair[1])"
                    $freq, $mo, $date, $time, $call, $exchAndT = $KeyValuePair[1] -Split " ", 6

                    $QsoObject = [PSCustomObject][ordered]@{}

                    #region Frequency or band
                    $ValidFrequencies = @(
                        "1800", "3500", "7000", "14000", "21000", "28000", # kHz
                        "50", "70", "144", "222", "432", "902", # MHz
                        "1.2G", "2.3G", "3.4G", "5.7G", "10G", "24G", "47G",
                        "75G", "123G", "134G", "241G", "LIGHT"
                    )
                    
                    Write-Verbose " - Found a frequency tag: $freq"
                    If (([int]$freq) -IsNot [int] -and $freq -NotIn $ValidFrequencies)
                    {
                        Throw [System.IO.InvalidDataException]::new("QSO frequencies must be a number or a defined band!")
                    }
                    Else
                    {
                        $MemberProperties = @{
                            "NotePropertyName"  = "Frequency"
                            "NotePropertyValue" = $freq
                        }
                        Add-Member -InputObject $QsoObject @MemberProperties
                    }
                    #endregion Frequency or band

                    #region Mode
                    Write-Verbose " - Found a transmitting mode tag: $mo"
                    If ($mo -NotIn @("CW", "PH", "FM", "RY", "DG"))
                    {
                        Throw [System.IO.InvalidDataException]::new("The mode $mo was not an accepted mode.")
                    }
                    Else
                    {
                        $MemberProperties = @{
                            "NotePropertyName"  = "Mode"
                            "NotePropertyValue" = $mo
                        }
                        Add-Member -InputObject $QsoObject @MemberProperties
                    }
                    #endregion Mode

                    #region Date
                    Write-Verbose " - Found a date tag: $date"
                    If ($date -NotMatch [RegEx]::"\d{4}-[01]\d-[0-3]\d")
                    {
                        Throw [System.IO.InvalidDataException]::new("The date was not formatted correctly.")
                    }
                    Else
                    {
                        # Cabrillo logs require UTC format, but PowerShell dates
                        # are always in the local format.  Thus, I'm having to
                        # "cast" it to a UTC time to make sure it gets handled
                        # properly.  There's got to be a better way.
                        $MemberProperties = @{
                            "NotePropertyName"  = "Date"
                            "NotePropertyValue" = (Get-Date -Date "$date $($time.Insert(2,":"))Z" -DisplayHint Date)
                        }
                        Add-Member -InputObject $QsoObject @MemberProperties
                    }
                    #endregion Date

                    #region Time
                    Write-Verbose " - Found a time tag: $time"
                    If ($time -NotMatch [RegEx]::"[0-2]\d[0-5]\d")
                    {
                        Throw [System.IO.InvalidDataException]::new("The time was not formatted correctly.")
                    }
                    Else
                    {
                        # Cabrillo logs require UTC format, but PowerShell dates
                        # are always in the local format.  Thus, I'm having to
                        # "cast" it to a UTC time to make sure it gets handled
                        # properly.  There's got to be a better way.
                        $MemberProperties = @{
                            "NotePropertyName"  = "Time"
                            "NotePropertyValue" = (Get-Date -Date "$date $($time.Insert(2,":"))Z" -DisplayHint Time)
                        }
                        Add-Member -InputObject $QsoObject @MemberProperties
                    }
                    #endregion Time

                    #region Call
                    Write-Verbose " - Found a call: $call"
                    If ($call -NotMatch [RegEx]::"[A-Z0-9\/]+")
                    {
                        Throw [System.IO.InvalidDataException]::new("The date was not formatted correctly.")
                    }
                    Else
                    {
                        $MemberProperties = @{
                            "NotePropertyName"  = "Call"
                            "NotePropertyValue" = $call
                        }
                        Add-Member -InputObject $QsoObject @MemberProperties
                    }
                    #endregion Call

                    #region Exchange
                    $exch = ($exchAndT -Split " ",-2)[0]
                    Write-Verbose " - Found a contest exchange: $exch"
                    $MemberProperties = @{
                        "NotePropertyName"  = "Exchange"
                        "NotePropertyValue" = $exch
                    }
                    Add-Member -InputObject $QsoObject @MemberProperties
                    Add-Member -InputObject $QsoObject -Type AliasProperty -Name "Exch" -Value "Exchange"
                    #endregion Exchange

                    #region Transmitter ID
                    $t = ($exchAndT -Split " ",-2)[1]
                    If ($t -ne "0" -and $t -ne "1")
                    {
                        Write-Warning "Found a QSO record without a valid transmitter ID.  This Cabrillo file is not well-formed."
                        If (-Not $NoTransmitterIDCheck)
                        {
                            Throw [System.IO.InvalidDataException]::new("The transmitter ID is not an accepted value.")
                        }
                    }
                    Else
                    {
                        $MemberProperties = @{
                            "NotePropertyName"  = "TransmitterID"
                            "NotePropertyValue" = $t
                        }
                        Add-Member -InputObject $QsoObject @MemberProperties
                    }
                    #endregion Transmitter ID

                    If ($KeyValuePair[0] -eq "X-QSO")
                    {
                        Write-Verbose " - Adding this QSO to the excluded QSO list."
                        If ($null -eq $CabrilloObject.QSO)
                        {
                            $CabrilloObject.QsoExcluded = @()
                        }
                        $CabrilloObject.QsoExcluded += $QsoObject
                    }
                    Else
                    {
                        Write-Verbose " - Adding this QSO to the QSO list."
                        If ($null -eq $CabrilloObject.QSO)
                        {
                            $CabrilloObject.QSO = @()
                        }
                        $CabrilloObject.QSO += $QsoObject
                    }
                }

                "X-(?!QSO)[^\s:]*"
                {
                    Write-Verbose "Ignoring an X- tag: $($KeyValuePair[1])"
                }

                "DEBUG"
                {
                    Write-Debug "Found a DEBUG tag with value $($KeyValuePair[1])."
                }

                "END-OF-LOG:?"
                {
                    Write-Debug "We've reached the end of the log."
                    $script:ReachedEndOfLog = $true
                    Break
                }

                default {
                    Throw [System.IO.InvalidDataException]::new("An invalid tag, $($KeyValuePair[0]), was found.")
                }
            }
        }
        $line++
    }

    End
    {
        If (-Not $script:ReachedEndOfLog)
        {
            Throw [System.IO.InvalidDataException]::new("Cabrillo logs must end with END-OF-LOG:")
        }

        # Add our custom type to the object, then return it.
        $CabrilloObject.PSObject.TypeNames.Insert(0, "PSCabrillo.CabrilloLog")
        Return $CabrilloObject
    }
}