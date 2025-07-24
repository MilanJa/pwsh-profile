# Development Tools Module
# Contains utility functions for development workflow

function Find-NearestPackageJson {
    param(
        [string]$StartDir = $PWD
    )

    $currentDir = $StartDir

    # Keep going up until we find a package.json file or reach the drive root
    while ($currentDir -ne "") {
        $packageJsonPath = Join-Path $currentDir "package.json"
        
        if (Test-Path $packageJsonPath) {
            return $packageJsonPath
        }

        # Move up one directory
        $parentDir = Split-Path -Parent $currentDir
        
        # If we've reached the drive root, $parentDir will equal $currentDir
        if ($parentDir -eq $currentDir) {
            return $null
        }
        
        $currentDir = $parentDir
    }

    return $null
}

function Open-Docs {
    # Script to fuzzy-find packages from package.json and open npm docs
    $packageJsonPath = Find-NearestPackageJson
    
    if (-not $packageJsonPath) {
        Write-Warning "No package.json found in this directory or any parent directories"
        return
    }
    
    # Show which package.json we're using
    $packageJsonDir = Split-Path -Parent $packageJsonPath
    Write-Host "Using package.json from: $packageJsonDir" -ForegroundColor Cyan
    
    $packageJson = Get-Content -Path $packageJsonPath | ConvertFrom-Json

    # Extract dependency names from both dependencies and devDependencies
    $dependencies = $packageJson.dependencies.PSObject.Properties.Name
    $devDependencies = $packageJson.devDependencies.PSObject.Properties.Name

    # Combine dependencies and mark them with their type
    $allDeps = @()
    foreach ($dep in $dependencies) {
        $allDeps += "$dep (dependency)"
    }
    foreach ($dep in $devDependencies) {
        $allDeps += "$dep (devDependency)"
    }

    # Use fzf to select a package
    $selectedPackage = $allDeps | Invoke-Fzf -Height 40% -ReverseInput -Border

    if ($selectedPackage) {
        # Extract just the package name (remove the type marker)
        $packageName = ($selectedPackage -split ' ')[0]
        Write-Host "Opening npm docs for $packageName..."
        npm docs $packageName
    }
}

function Open-With-VSCode {
    [alias('cs')]
    param(
        [string]$StartPath = "."
    )

    # Use Invoke-Fzf to select a file with preview
    $selectedFile = Get-ChildItem -Path $StartPath -Recurse -File |
    Select-Object -ExpandProperty FullName |
    Invoke-Fzf -Preview { bat -f {} } 

    if ($selectedFile) {
        # Open the selected file in VS Code
        code $selectedFile
    }
    else {
        Write-Host "No file selected."
    }
}

Export-ModuleMember -Function Find-NearestPackageJson, Open-Docs, Open-With-VSCode -Alias cs
