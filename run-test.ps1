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
$total = 0
$success = 0
Get-ChildItem -Path "comparison" -File -Name | ForEach-Object {
  if ($_ -match "-ref") {
    $total = $total + 1

    $ref = $_
    # Remove the -ref suffix to find get to the image that we want to test
    $f = $_ -replace "-ref.png", ".png"

    # Check if the newly created file exists
    if (!(Test-Path "comparison/$f")) {
      Write-Output "    Could not find file: $f"
      return;
    }
    $ref_hash = Get-FileHash "comparison/$ref"
    $f_hash = Get-FileHash("comparison/$f")
    if ($f_hash.hash -eq $ref_hash.hash) {
      $success = $success + 1
    }
    else {
      Write-Output "    Hash changed: $f"
    }
  }
  else {
    # For all of the created images, make sure that a reference image exists as a safety net
    $f = $_
    $ref = $_ -replace ".png", "-ref.png"
    if (!(Test-Path "comparison/$ref")) {
      Write-Output "    No corresponding reference file found: $f"
    }
  }
}
Write-Output "============"
Write-Output "Results: $success / $total tests succeeded"
