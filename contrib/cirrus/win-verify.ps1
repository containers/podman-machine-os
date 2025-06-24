Write-Host "Recovering env. vars."
Import-CLIXML "$ENV:TEMP\envars.xml" | % {
    Write-Host "    $($_.Name) = $($_.Value)"
    Set-Item "Env:$($_.Name)" "$($_.Value)"
}

# Output info so we know what version we are testing.
wsl --version

$Env:CONTAINERS_MACHINE_PROVIDER = "${ENV:PROVIDER}"
$Env:MACHINE_IMAGE_PATH="..\${ENV:MACHINE_IMAGE}"
.\bin\ginkgo -v .\verify
if ( ($LASTEXITCODE -ne $null) -and ($LASTEXITCODE -ne 0) ) {
    throw "Exit code = '$LASTEXITCODE' running ginkgo"
}
