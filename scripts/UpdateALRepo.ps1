param(
    $Localization = '',
    $Version = '',
    $BuildFolder = '',
    $SourcePath,
    $RepoPath = ''
)

if (-not $SourcePath) {
    $SourcePath = "~/.bcartifacts.cache/sandbox/$Version/$Localization/Applications.DE/"
}

$zips = Get-ChildItem -Path $SourcePath -Filter *.zip -Recurse
Get-ChildItem -Path $RepoPath -Directory -Exclude scripts, .git | Remove-Item -Recurse -Force

foreach ($zip in $zips) {
    $RelativePath = $zip.FullName -ireplace [regex]::Escape($SourcePath + '/'), '' 
    $ZipTargetPath = Join-Path $RepoPath (Split-Path -Path $RelativePath)
    $ZipNameForTarget = (Split-Path -Path $RelativePath -Leaf).Replace('.zip', '').Replace('..Source', '').Replace('.Source', '')
    $ZipTargetPath = (Join-Path $ZipTargetPath $ZipNameForTarget)
    7z x $zip.FullName -o"$ZipTargetPath" -r -y | out-null
}


