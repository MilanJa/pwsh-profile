# PowerShell Profile Modules

This directory contains modular PowerShell profile components organized by functionality.

## Module Structure

### `Aliases.psm1`
- Basic command aliases (`pn`, `p`, `lg`, `cat`)
- Function aliases (`prd`, `pe`, `dcu`, `dc`)
- Short commands for common development tasks

### `RepositoryManagement.psm1`
- Multi-repository management functions
- Branch checking and updating (`Show-CurrentBranches`, `Update-All-Repos`)
- Repository switching and status functions
- Startup function (`up`) for development environment

### `DevelopmentTools.psm1`
- Development workflow utilities
- Package.json discovery (`Find-NearestPackageJson`)
- NPM documentation browser (`Open-Docs`)
- File selection and VS Code integration (`Open-With-VSCode`)

### `GitUtilities.psm1`
- Git helper functions
- Interactive branch switching (`gs`)
- Git aliases browser (`ghelp`)

### `TerminalEnhancements.psm1`
- Terminal UI improvements
- Enhanced file listing (`Eza`)
- PSReadLine prediction view toggling (`Set-PredictionView`)
- Broot integration (`br`)

### `GitHubCompletions.psm1`
- GitHub CLI auto-completion
- Tab completion for `gh` commands
- Supports all PowerShell completion modes

## Usage

Import all modules by sourcing the main profile:
```powershell
. $PROFILE
```

Or import individual modules as needed:
```powershell
Import-Module "$env:USERPROFILE\.pwsh\Aliases.psm1" -Force
```

## Module Development

When adding new functions:
1. Add the function to the appropriate module
2. Export it using `Export-ModuleMember`
3. Reload the module with `-Force` flag

Example:
```powershell
Export-ModuleMember -Function MyNewFunction -Alias mnf
```

## Backup

Your original profile has been preserved as `Microsoft.PowerShell_profile.ps1`.
The new modular profile is available as `Microsoft.PowerShell_profile_modular.ps1`.

To switch to the modular version:
```powershell
Copy-Item "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile_modular.ps1" "$PROFILE"
```
