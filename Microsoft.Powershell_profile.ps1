# PowerShell Profile - Modular Configuration
# Main profile that imports all custom modules

# Initialize prompt and navigation tools
Invoke-Expression (&starship init powershell) # prompt
Invoke-Expression (& { (zoxide init powershell | Out-String) }) # zoxide cd jumper

# Carapace auto-completion setup
$env:CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense' 
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
carapace _carapace | Out-String | Invoke-Expression

# Import custom modules
$ModulePath = "$env:USERPROFILE\.pwsh"

Import-Module "$ModulePath\Aliases.psm1" -DisableNameChecking -Force
Import-Module "$ModulePath\RepositoryManagement.psm1" -DisableNameChecking -Force
Import-Module "$ModulePath\DevelopmentTools.psm1" -DisableNameChecking -Force
Import-Module "$ModulePath\GitUtilities.psm1" -DisableNameChecking -Force
Import-Module "$ModulePath\TerminalEnhancements.psm1" -DisableNameChecking -Force
Import-Module "$ModulePath\GitHubCompletions.psm1" -DisableNameChecking -Force

# Import external modules
Import-Module git-aliases -DisableNameChecking
Import-Module 'gsudoModule'
Import-Module posh-git

# Configure PSReadLine
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
