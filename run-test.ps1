param (
  [Parameter(Mandatory=$true)][string]$application = "test-runner.exe"
)

if (!(Test-Path -Path $application -PathType Leaf)) {
  Write-Output "Could not find application $application"
}

# Create new comparison directory
if (Test-Path -Path "comparison") {
  Remove-Item -Path "comparison" -Recurse
}
New-Item -Path . -Name "comparison" -ItemType "directory" | Out-Null

# Copy over the reference images
Write-Output "Copying reference images..."
Copy-Item -Path "reference/*" -Destination "comparison" -Recurse
# Rename reference images by adding a "-ref" to the end
Get-ChildItem -Path "comparison" -File | Rename-Item -NewName {$_.name -replace ".png", "-ref.png" }
# Create the test images
Write-Output "Creating test images..."
Start-Process -FilePath $application -ArgumentList "-config full_test.xml -local 1 -client"
Start-Process -FilePath $application -ArgumentList "-config full_test.xml" -Wait
# Copy current files into comparison folder
Move-Item -Path "SGCT*.png" -Destination "comparison"

Write-Output "Comparing..."
Write-Output "============"
Get-ChildItem -Path "comparison" -File -Name | ForEach-Object {
    if (!($_ -match "-ref")) {
        $f = $_
        $f_hash = Get-FileHash "comparison/$f"
        $ref = $_ -replace ".png", "-ref.png"
        $ref_hash = Get-FileHash("comparison/$ref")
        if (!($f_hash.hash -eq $ref_hash.hash)) {
            Write-Output "    Hash changed: $f"
        }
    }
}
Write-Output "============"
Write-Output "If there were no messages between the lines, the compared images are the same"
