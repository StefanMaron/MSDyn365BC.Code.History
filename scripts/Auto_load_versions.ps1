param (
    [string]$country = 'w1'
)

$ErrorActionPreference = "SilentlyContinue"

[System.Collections.ArrayList]$Versions = @()
# Get-BCArtifactUrl -select All -Type OnPrem -country $country -after ([DateTime]::Today.AddDays(-1)) | % {
Get-BCArtifactUrl -select All -Type OnPrem -country $country | % {
    [System.Uri]$Url = $_
    $TempString = $Url.AbsolutePath
    [version]$Version = $TempString.Split('/')[2]
    $country = $TempString.Split('/')[3]

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
    $country = $_.Country.Trim()
    Write-Host ($($country)-$($version.ToString()))
    
    git fetch --all

    $LastCommit = git log --all --grep="^$($country)-$($version.ToString())$"

    if ($LastCommit.Length -eq 0) {
        Write-Host "###############################################"
        Write-Host "Processing $($country) - $($Version.ToString())"
        Write-Host "###############################################"
        
        $LatestCommitIDOfBranchEmpty = git log -n 1 --pretty=format:"%h" "master"
        if ($LatestCommitIDOfBranchEmpty -eq $null) {
            $LatestCommitIDOfBranchEmpty = git log -n 1 --pretty=format:"%h" "origin/master"
        }

        if ($Version.Major -gt 15 -and $Version.Build -gt 5) {
            $CommitIDLastCUFromPreviousMajor = git log --all -n 1 --grep="^$($country)-$($version.Major - 1).5" --pretty=format:"%h"
        }
        else {
            $CommitIDLastCUFromPreviousMajor = $null
        }

        $BranchAlreadyExists = ((git branch --list -r "origin/$($country)-$($Version.Major)") -ne $null) -or ((git branch --list "$($country)-$($Version.Major)") -ne $null)

        if ($BranchAlreadyExists) {
            git switch "$($country)-$($Version.Major)"
        }
        else {
            if ($CommitIDLastCUFromPreviousMajor -ne $null) {
                git switch -c "$($country)-$($Version.Major)" $CommitIDLastCUFromPreviousMajor
            }
            else {
                git switch -c "$($country)-$($Version.Major)" $LatestCommitIDOfBranchEmpty                
            }
        }
        
        if ($country -eq 'w1'){
            $Paths = Download-Artifacts -artifactUrl $_.URL -includePlatform
            $LocalizationPath = $Paths[0]
            $PlatformPath = $Paths[1]
        }
        else {
            $Paths = Download-Artifacts -artifactUrl $_.URL
            $LocalizationPath = $Paths
            $PlatformPath = ''
        }

        #Localization folder
        
        $TargetPathOfVersion = (Join-Path $LocalizationPath (Get-ChildItem -Path $LocalizationPath -filter "Applications")[0].Name)

        if (-not (Test-Path $TargetPathOfVersion)) {
            #Platform Folder
            $TargetPathOfVersion = (Join-Path $PlatformPath (Get-ChildItem -Path $PlatformPath -filter "Applications")[0].Name)
        }
        
        & "scripts/UpdateALRepo.ps1" -SourcePath $TargetPathOfVersion -RepoPath (Split-Path $PSScriptRoot -Parent) -Version $version -Localization $country
        & "scripts/BuildTestsWorkSpace.ps1"
        
        Get-ChildItem -Recurse -Filter "*.xlf" | Remove-Item

        "$($country)-$($version.ToString())" > version.txt

        git config user.email "stefanmaron@outlook.de"
        git config user.name "Stefan Maron"
        git add -A | out-null
        git commit -a -m "$($country)-$($version.ToString())" | out-null
        git gc | out-null
        git push --set-upstream origin "$($country)-$($Version.Major)"
        
        Flush-ContainerHelperCache -keepDays 0 -ErrorAction SilentlyContinue

        Write-Host "$($country)-$($version.ToString())"
    }
    else {
        Write-Host "###############################################"
        Write-Host "Skipped version $($country) - $($version.ToString())"
        Write-Host "###############################################"
    }
}

 
