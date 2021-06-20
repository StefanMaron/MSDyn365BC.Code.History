$Directories = Get-ChildItem -Directory -Filter "*test*" -Recurse

$workspace = @{}
$workspace["folders"] = @()

$Directories | % {
    $Childs = Get-ChildItem -Path $_.FullName -Directory -Filter "*test*" 
    if ($Childs.Count -eq 0 ) {
        $path = @{}
        $path["path"] = (Get-Item $_.FullName | Resolve-Path -Relative)

        $workspace["folders"] += $path
    }
}

$workspace["settings"] = @{}

$workspace["settings"]["allint.enabled"] = $false
$workspace["settings"]["al.enableCodeActions"] = $false
$workspace["settings"]["al.enableCodeAnalysis"] = $false
$workspace["settings"]["search.exclude"] = @{"**.xlf" = $true }

$workspace | ConvertTo-Json | Out-File "test-apps.code-workspace" -Encoding utf8

