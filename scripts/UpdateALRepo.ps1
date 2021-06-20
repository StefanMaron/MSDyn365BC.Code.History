param(
    $Localization = '',
    $Version = '',
    $BuildFolder = '',
    $SourcePath,
    $RepoPath = '',
    $7zipExe = 'C:\Program Files\7-Zip\7z.exe'
)

if (-not $SourcePath) {
    $SourcePath = "C:\bcartifacts.cache\onprem\$Version\$Localization\Applications"
}

Set-Alias sz $7zipExe
$zips = Get-ChildItem -Path $SourcePath -Filter *.zip -Recurse
Get-ChildItem -Path $RepoPath -Directory -Exclude scripts, .git | Remove-Item -Recurse -Force

foreach ($zip in $zips) {
    $RelativePath = $zip.FullName -ireplace [regex]::Escape($SourcePath + '\'), '' 
    $ZipTargetPath = Join-Path $RepoPath (Split-Path -Path $RelativePath)
    $ZipNameForTarget = (Split-Path -Path $RelativePath -Leaf).Replace('.zip', '').Replace('..Source', '').Replace('.Source', '')
    $ZipTargetPath = (Join-Path $ZipTargetPath $ZipNameForTarget)
    sz x $zip.FullName -o"$ZipTargetPath" -r -y | out-null
}


