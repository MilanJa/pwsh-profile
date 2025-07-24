# Aliases Module
# Contains all custom aliases and short commands

# Basic aliases
Set-Alias -Name pn -Value pnpm
Set-Alias -Name p -Value pnpm
Set-Alias -Name lg -Value lazygit
Set-Alias -Name cat -Value bat

# Function aliases
function prd { pnpm run dev }
function pe { pnpm exec $args }

function dcu { docker compose up }
function dc { docker compose $args }

# Export functions so they're available when module is imported
Export-ModuleMember -Function prd, pe, dcu, dc -Alias pn, p, lg, cat
