<#
.SYNOPSIS
Exports a simple visual representation of the Places directory structure

.DESCRIPTION
Exports a simple visual representation of the Places directory structure, showing the hierarchy of sections, rooms, spaces, and desks.
The output is a text-based tree structure that is displayed in the console or can be saved to a file.

.NOTES
Requires the Places PowerShell Module to be installed and for you to be authenticated to the Places service.

.EXAMPLE
PS> .\Export-SimplePlacesVisual.ps1

This command exports the Places directory structure to the console in a simple text format.

OUTPUT:

Building | Contoso HQ 
         |--- Floor    | 1
                       |--- Section  | HQ.1.North
                                     |--- Space    | Workspace HQ/1.400
                       |--- Section  | HQ.1.NorthEast
                                     |--- Space    | Workspace HQ/1.300
                                     |--- Space    | Workspace HQ/1.360
                                     |--- Desk     | Office HQ/1.390
                       |--- Room     | ConfRm HQ/1.019
                       |--- Room     | ConfRm HQ/1.031
                       |--- Room     | ConfRm HQ/1.143
         |--- Floor    | 2
                       |--- Section  | HQ.2.North
                                     |--- Space    | Workspace HQ/2.400
                       |--- Section  | HQ.2.NorthEast
                                     |--- Space    | Workspace HQ/2.300
                                     |--- Space    | Workspace HQ/2.370
                                     |--- Desk     | Office HQ/2.390
                       |--- Room     | ConfRm HQ/2.033
                       |--- Room     | ConfRm HQ/2.057
                       |--- Room     | ConfRm HQ/2.143


.EXAMPLE
PS> .\Export-SimplePlacesVisual.ps1 -IncludePlaceId -OutputFileName "PlacesDirectory.txt"

This command exports the Places directory structure to an text file named "PlacesDirectory.txt" in the current directory, including PlaceId for each object.

OUTPUT FILE CONTENT (PlacesDirectory.txt):

Building | Contoso HQ | a38cf291-393c-4341-b387-2f96540512cb
         |--- Floor    | 1 | ea850f6e-4e50-4f77-ba81-f2181c1875a9
                       |--- Section  | HQ.1.North | ff8579b8-8937-48c1-9c70-c88fab984421
                                     |--- Space    | Workspace HQ/1.400 | 4abf3982-c053-498d-81a3-4e42088b0271
                       |--- Section  | HQ.1.NorthEast | b4c6fbe5-2b37-4ebb-a1d5-a6f2654de9c9
                                     |--- Space    | Workspace HQ/1.300 | 3a069930-44c1-4009-8ac4-5debd6242361
                                     |--- Space    | Workspace HQ/1.360 | cc5e3196-517f-4f9a-8b7e-43260cdedbf9
                                     |--- Desk     | Office HQ/1.390 | 5bab80cc-b88e-4082-a010-0bb3d5c2ff31
                       |--- Room     | ConfRm HQ/1.019 | 86ce0ce5-6cbb-40ec-b5bf-20f1430372af
                       |--- Room     | ConfRm HQ/1.031 | 68ea1e13-8019-4cb4-86f4-d1a318af90ad
                       |--- Room     | ConfRm HQ/1.143 | ac38bd70-b149-43c1-85bd-6f431b552958
         |--- Floor    | 2 | eac6c494-ec67-43c8-92db-99840ced7c5f
                       |--- Section  | HQ.2.North | f7dcee8c-cf9f-4088-9fbe-9d97508ea477
                                     |--- Space    | Workspace HQ/2.400 | e5ff28ab-f08f-4561-a28e-9990a1961669
                       |--- Section  | HQ.2.NorthEast | 98be95d1-9880-4a7e-8499-66f31e408762
                                     |--- Space    | Workspace HQ/2.300 | fb49ca0d-3b36-4aea-a280-5adeece17a21
                                     |--- Space    | Workspace HQ/2.370 | 0ddca668-58eb-4a1d-ab14-ca36f04ab7c3
                                     |--- Desk     | Office HQ/2.390 | bd98ba7d-aafd-448b-b754-19397084afa4
                       |--- Room     | ConfRm HQ/2.033 | a5b6ef95-6ad1-4b5c-84bb-d7ede0467d74
                       |--- Room     | ConfRm HQ/2.057 | c4179b01-4268-4ab9-b772-e9d262237b79
                       |--- Room     | ConfRm HQ/2.143 | 9ad63633-2b64-4e14-b652-5a881980f217

.EXAMPLE
PS> .\Export-SimplePlacesVisual.ps1 -AncestorId "eac6c494-ec67-43c8-92db-99840ced7c5f" -IncludePlaceId

This command exports the Places directory structure starting from the specified ancestor PlaceId "eac6c494-ec67-43c8-92db-99840ced7c5f" (2nd Floor), including PlaceId for each object in the output.

OUTPUT:

|--- Floor    | 2 | eac6c494-ec67-43c8-92db-99840ced7c5f
              |--- Section  | HQ.2.North | f7dcee8c-cf9f-4088-9fbe-9d97508ea477
                            |--- Space    | Workspace HQ/2.400 | e5ff28ab-f08f-4561-a28e-9990a1961669
              |--- Section  | HQ.2.NorthEast | 98be95d1-9880-4a7e-8499-66f31e408762
                            |--- Space    | Workspace HQ/2.300 | fb49ca0d-3b36-4aea-a280-5adeece17a21
                            |--- Space    | Workspace HQ/2.370 | 0ddca668-58eb-4a1d-ab14-ca36f04ab7c3
                            |--- Desk     | Office HQ/2.390 | bd98ba7d-aafd-448b-b754-19397084afa4
              |--- Room     | ConfRm HQ/2.033 | a5b6ef95-6ad1-4b5c-84bb-d7ede0467d74
              |--- Room     | ConfRm HQ/2.057 | c4179b01-4268-4ab9-b772-e9d262237b79
              |--- Room     | ConfRm HQ/2.143 | 9ad63633-2b64-4e14-b652-5a881980f217

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
