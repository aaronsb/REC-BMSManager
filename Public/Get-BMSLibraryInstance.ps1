Function Get-BMSLibraryInstance {
    $LibraryPath = (Join-Path -Path $PSScriptRoot -ChildPath "../instructionset.json")
    (gc $LibraryPath | ConvertFrom-Json)
}
