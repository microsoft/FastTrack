# get the -verbose and -debug params from the command line
[cmdletbinding()]

param(
    [ValidateNotNullOrEmpty()]
    [String]
    $file,
    [String]
    $splitColumn = "Message",
    [String]
    $outFolder = (Split-Path -Path $MyInvocation.MyCommand.Path -Parent)
)

begin { 
    Clear-Host

    Write-Host "Microsoft FastTrack SPMT Error Log Splitter"

    Write-Host "Splitting error log $($file) using column $($splitColumn)"

    # ensure the folder exists
    New-Item -ItemType Directory -Force -Path $outFolder | Out-Null

    Write-Host "Writing files to output folder $($outFolder)"
}

process {

    # read these once
    $chars = [System.IO.Path]::GetInvalidFileNameChars()
    # done so we don't have to calculate the filename each time for performance
    $fileNameMap = @{}

    Import-Csv $file -Delimiter "," | 
        ForEach-Object {

        $fileName = $fileNameMap[$_.$splitColumn]
        $skip = 1

        if ($fileName -eq $null) {

            $fileName = "split_$($_.$splitColumn).csv"

            foreach ($c in $chars) {
                $fileName = $fileName.Replace($c, '_')
            }

            Write-Host "Creating file $($fileName)"

            # only write the headers once
            $skip = 0
            $fileName = Join-Path -Path $outFolder -ChildPath $($fileName)

            $fileNameMap.Add($_.$splitColumn, $fileName) 
        }

        $_ | ConvertTo-Csv -Delimiter "," -NoTypeInformation | Select-Object -Skip $skip | Out-File $fileName -Enc ascii -Append
    } 
}

end {
    Write-Host "SPMT Error log splitting complete, ending"
}
