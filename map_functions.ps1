$lines = Get-Content -Path 'index-standalone.html' -Encoding UTF8
$matches = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -match 'function\s+(db[a-zA-Z0-9_]+|render[a-zA-Z0-9_]+|save[a-zA-Z0-9_]+|go[a-zA-Z0-9_]+)') {
        $matches += "$($i+1): $line"
    }
}
$matches | Out-File -FilePath 'functions_map.txt' -Encoding UTF8
Write-Output "Found $($matches.Count) functions. Check functions_map.txt"
