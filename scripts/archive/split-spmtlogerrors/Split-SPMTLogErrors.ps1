# get the -verbose and -debug params from the command line
[cmdletbinding()]

param(
    [ValidateNotNullOrEmpty()]
    [string]
    $file,
    [string]
    $splitColumn = "Message",
    [string]
    $outFolder = (Split-Path -Path $MyInvocation.MyCommand.Path -Parent),
    [switch]
    $getSelectFile,
    [switch]
    $getColumnReport,
    [string]
    $selectFile = $null
)

begin { 
    Clear-Host
    Write-Host "Microsoft FastTrack SPMT Error Log Splitter"
}

process {

    if ($getSelectFile) {

        $outFile = "selects.txt"

        Write-Host "Gathering unique values in error log $($file) for column $($splitColumn)"

        Write-Host "Writing output to $($outFile)"

        Import-Csv $file -Delimiter "," | 
            Group-Object { $_.$splitColumn } | 
            Select-Object -ExpandProperty Name | 
            Set-Content -Path $outFile
    }
    elseif ($getColumnReport) {

        Write-Host "Gathering unique values report for error log $($file) for column $($splitColumn)"

        Import-Csv $file -Delimiter "," |
            Group-Object { $_.$splitColumn } |
            Select-Object Count, Name |
            Sort-Object Count -Descending |
            Format-Table
    }
    elseif (-Not [System.String]::IsNullOrEmpty($selectFile)) {

        $outFile = "filtered.csv"

        Write-Host "Reading select values from $($selectFile) for column $($splitColumn)"

        Write-Host "Writing output to $($outFile)"

        # read the lines of the file
        $lines = Get-Content -Path $selectFile

        Import-Csv $file -Delimiter "," | 
            Where-Object { $_.$splitColumn -in $lines } | 
            ConvertTo-Csv -Delimiter "," -NoTypeInformation | 
            Out-File $outFile -Enc ascii -Append
    }
    else {

        Write-Host "Splitting error log $($file) using column $($splitColumn)"

        # ensure the folder exists
        New-Item -ItemType Directory -Force -Path $outFolder | Out-Null
    
        Write-Host "Writing files to output folder $($outFolder)"

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

            $_ | 
                ConvertTo-Csv -Delimiter "," -NoTypeInformation | 
                Select-Object -Skip $skip | 
                Out-File $fileName -Enc ascii -Append
        }  
    }    
}

end {
    Write-Host "...ending."
}
