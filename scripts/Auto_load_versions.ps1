$ErrorActionPreference = "SilentlyContinue"

Set-Alias sz "C:\Program Files\7-Zip\7z.exe"

[System.Collections.ArrayList]$Versions = @()
Get-BCArtifactUrl -select All -Type OnPrem | % {
    $Url = $_
    $TempString = $Url.Substring(41)
    [version]$Version = $TempString.Substring(0, $TempString.IndexOf('/'))
    $country = $TempString.Substring($TempString.IndexOf('/') + 1)

    [hashtable]$objectProperty = @{}
    $objectProperty.Add('Version', $Version)
    $objectProperty.Add('Country', $country)
    $objectProperty.Add('URL', $Url)
    $ourObject = New-Object -TypeName psobject -Property $objectProperty

    if ($Version -ge [version]::Parse('15.0.0.0')) {
        $Versions.Add($ourObject)
    }
}

$Versions | Sort-Object -Property Country, Version | % {
    [version]$Version = $_.Version
    $country = $_.Country

    $CommitDoesNotExist = (git log --all --grep="$($country)-$($version.ToString())") -eq $null

    if ($CommitDoesNotExist) {
        Write-Host "###############################################"
        Write-Host "Processing $($country) - $($Version.ToString())"
        Write-Host "###############################################"


        $LatestCommitIDOfBranchEmpty = git log -n 1 --pretty=format:"%h" "empty"
        if ($LatestCommitIDOfBranchEmpty -eq $null) {
            $LatestCommitIDOfBranchEmpty = git log -n 1 --pretty=format:"%h" "origin/empty"
        }

        if ($Version.Major -gt 15 -and $Version.Build -gt 5) {
            $CommitIDLastCUFromPreviousMajor = git log --all --grep="$($country)-$($version.Major - 1).5" --pretty=format:"%h"
        }
        else {
            $CommitIDLastCUFromPreviousMajor = $null
        }

        $BranchAlreadyExists = ((git branch --list -r "*$($country)-$($Version.Major)*") -ne $null) -or ((git branch --list "*$($country)-$($Version.Major)*") -ne $null)

        if ($BranchAlreadyExists) {
            git checkout "$($country)-$($Version.Major)"
        }
        else {
            if ($CommitIDLastCUFromPreviousMajor -ne $null) {
                git checkout -b "$($country)-$($Version.Major)" $CommitIDLastCUFromPreviousMajor
            }
            else {
                git checkout -b "$($country)-$($Version.Major)" $LatestCommitIDOfBranchEmpty                
            }
        }
        
        $Paths = Download-Artifacts -artifactUrl $_.URL -includePlatform
        $TargetPathOfVersion = $Paths[0]

        if (-not (Test-Path (Join-Path $TargetPathOfVersion 'Applications'))) {
            $TargetPathOfVersion = $Paths[1]
        }
        
        & "$PSScriptRoot\UpdateALRepo.ps1" -SourcePath (Join-Path $TargetPathOfVersion Applications) -RepoPath (Split-Path $PSScriptRoot -Parent)
        & "$PSScriptRoot\BuildTestsWorkSpace.ps1"

        git add -A | out-null
        git commit -a -m "$($country)-$($version.ToString())" | out-null
        git gc | out-null
        
        Remove-Item $Paths[0] -Recurse

        Write-Host "$($country)-$($version.ToString())"
    }
    else {
        Write-Host "###############################################"
        Write-Host "Skipped version $($country) - $($version.ToString())"
        Write-Host "###############################################"
    }
}

 