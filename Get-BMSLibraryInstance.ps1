Function Get-BMSLibraryInstance {
    (gc .\instructionset.json | ConvertFrom-Json)
}