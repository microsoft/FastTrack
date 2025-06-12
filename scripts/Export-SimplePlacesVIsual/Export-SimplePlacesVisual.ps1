<#
.SYNOPSIS
    Exports a simple visual representation of the Places directory structure
.DESCRIPTION
    Exports a simple visual representation of the Places directory structure, showing the hierarchy of sections, rooms, spaces, and desks.
    The output is a text-based tree structure that is displayed in the console or can be saved to a file.
.NOTES
    Requires the Places PowerShell Module to be installed and for you to be authenticated to the Places service.
.EXAMPLE
    Export-SimplePlacesVisual.ps1
    This command exports the Places directory structure to the console in a simple text format.
.EXAMPLE
    Export-SimplePlacesVisual.ps1 -IncludePlaceId -OutputFileName "PlacesDirectory.txt"
    This command exports the Places directory structure to an text file named "PlacesDirectory.txt" in the current directory, including PlaceId for each object.
.EXAMPLE
    Export-SimplePlacesVisual.ps1 -AncestorId "12345" -IncludePlaceId
    This command exports the Places directory structure starting from the specified ancestor PlaceId "12345", including PlaceId for each object in the output.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false,
        HelpMessage = "Include this flag for the output to add the PlaceId for each object to the output")]
    [switch]
    $IncludePlaceId,

    [Parameter(Mandatory = $false,
        HelpMessage = "Specify the parent object to start the output at. For example, provide the PlaceId of a single building.")]
    [string]
    $AncestorId,

    # Specifies a filename to save the output to in the working directory
    [Parameter(Mandatory=$false,
        HelpMessage="Specify the name of the file to output to in current directory")]
    [ValidateNotNullOrEmpty()]
    [string]
    $OutputFileName
)

# Check if the Places PowerShell Module is installed
if (-not (Get-Command "Get-PlaceV3")) {
    throw "Install the Places PowerShell Module"
}

# Get the Places directory, accounting for if the AncestorId is provided
try {
    if ($AncestorId) {
        try {
            $script:PlacesDirectory = Get-PlaceV3 -AncestorId $AncestorId
        } catch {
            # If the AncestorId is not found, we try to get the place directly with the same PlaceId
            if ($_.Exception.Message -like "*NotFound*") {
                Write-Verbose "'Get-PlaceV3 -AncestorId' did not find a resource, trying to find it individually"
                try {
                    $script:PlacesDirectory = Get-PlaceV3 -Identity $AncestorId
                } catch {
                    if ($_.Exception.Message -like "*NotFound*") {
                        throw "AncestorId provided '$($AncestorId)' Not Found in the Places directory"
                    }
                }
            }
        }
        # If the Place we returned is a section by itself, we need to get the directory up a level via the section's parent to then get the children of that section.
        if (($script:PlacesDirectory.count -eq 1) -and ($script:PlacesDirectory.Type -eq "Section")) {
            write-Verbose "'Get-PlaceV3 -AncestorId' won't return children items for a section, so need to do some extra work to get them for this script."
            $Section = $script:PlacesDirectory
            $SectionParentDirectory = Get-PlaceV3 -AncestorId $Section.ParentId
            $script:PlacesDirectory = $SectionParentDirectory | where {($_.ParentId -eq $AncestorId) -or ($_.PlaceId -eq $AncestorId)}
        }
        Write-Verbose "Found $($script:PlacesDirectory.count) places in the Places directory starting at AncestorId $($AncestorId)"
    } else {
        $script:PlacesDirectory = Get-PlaceV3
        Write-Verbose "Found $($script:PlacesDirectory.count) places in the Places directory"
    }
} catch {
    throw $_
}

$script:Output = ""

function OutputChildPlaces {
    param (
        [string]$ParentId,
        [string]$LeftPaddingString = "              ",
        [string]$IndentString = "         |--- ",
        [string]$Separator = " | "
    )
    $ThisChildOutput = ""
    
    if ($ParentId) {
        $ChildPlaces = $script:PlacesDirectory | where ParentId -eq $ParentId

        if ($ChildPlaces) {
            # Sort the child places by type and then by display name
            $ChildPlacesSorted = @()
            $ChildPlacesSorted += @($ChildPlaces | where Type -eq "Floor") | Sort-Object -Property DisplayName
            $ChildPlacesSorted += @($ChildPlaces | where Type -eq "Section") | Sort-Object -Property DisplayName
            $ChildPlacesSorted += @($ChildPlaces | where Type -eq "Room") | Sort-Object -Property DisplayName
            $ChildPlacesSorted += @($ChildPlaces | where Type -eq "Space") | Sort-Object -Property DisplayName
            $ChildPlacesSorted += @($ChildPlaces | where Type -eq "Desk") | Sort-Object -Property DisplayName
            $ChildPlacesSorted += @($ChildPlaces | where {$_.Type -ne "Floor" -and $_.Type -ne "Section" -and $_.Type -ne "Room" -and $_.Type -ne "Space" -and $_.Type -ne "Desk"}) | Sort-Object -Property DisplayName

            foreach ($childPlace in $ChildPlacesSorted) {
                $ThisChildOutputString = ""
                $NextDownChildOutput = ""
                $ThisChildOutput += "`n" # move to the next line of output

                Write-Debug "Adding $($childPlace.DisplayName) to output"
                if ($IncludePlaceId) {
                    $ThisChildOutputString = $LeftPaddingString + $IndentString + $childPlace.Type.PadRight(8,' ') + $Separator + $childPlace.DisplayName + $Separator + $childPlace.PlaceId
                } else {
                    $ThisChildOutputString = $LeftPaddingString + $IndentString + $childPlace.Type.PadRight(8,' ') + $Separator + $childPlace.DisplayName
                }

                # Recursively call this function to get the next level of children, adding additional indentation
                $NextDownChildOutput = OutputChildPlaces $childPlace.PlaceId -LeftPaddingString ($LeftPaddingString + "              ") -IndentString $IndentString -Separator $Separator

                $ThisChildOutput += $ThisChildOutputString
                $ThisChildOutput += $NextDownChildOutput
            }
            $ThisChildOutput
        }
    }
}

if ($script:PlacesDirectory) {
    if ($AncestorId) {
        $TopLevelPlaces = $script:PlacesDirectory | where {$_.PlaceId -eq $AncestorId}
        Write-Verbose "Starting with top level place specified by AncestorId $($AncestorId)"
    } else {
        $TopLevelPlaces = $script:PlacesDirectory | where {(-not $_.ParentId) -and ($_.Type -ne "RoomList")}
        Write-Verbose "There are $($TopLevelPlaces.count) top level places that aren't room lists"
    }

    # Sort the top level places, putting buildings first, then sorting by display name
    $TopLevelPlaces = ($TopLevelPlaces | where Type -eq "Building" | Sort-Object -Property DisplayName) + ($TopLevelPlaces | where Type -ne "Building" | Sort-Object -Property DisplayName)

    $Separator = " | "

    foreach ($topLevelPlace in $TopLevelPlaces) {
        $ThisPlaceOutputString = ""
        $ChildOutput = ""

        $script:Output += "`n" # move to the next line of output

        Write-Debug "Adding $($topLevelPlace.DisplayName) to output"
        if ($IncludePlaceId) {
            $ThisPlaceOutputString = $topLevelPlace.Type.PadRight(8,' ') + $Separator + $topLevelPlace.DisplayName + $Separator + $topLevelPlace.PlaceId
        } else {
            $ThisPlaceOutputString = $topLevelPlace.Type.PadRight(8,' ') + $Separator + $topLevelPlace.DisplayName
        }

        $ChildOutput = OutputChildPlaces -ParentId $topLevelPlace.PlaceId -LeftPaddingString ""
        
        $script:Output += $ThisPlaceOutputString
        $script:Output += $ChildOutput
        $script:Output += "`n"
    }
    $script:Output += "`n" # one extra line at the bottom

    if ($OutputFileName) {
        Write-Debug ("OutputFileName : " + $OutputFileName)
        if ($OutputFileName -notlike "*.html" -and $OutputFileName -notlike "*.htm") {
            $OutputFileName += ".html"
        }
        $script:Output | Out-File $OutputFileName
    } else {
        $script:Output
    }
} else {
    throw "Empty Places Directory"
}
