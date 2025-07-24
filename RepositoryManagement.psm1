# Repository Management Module
# Contains functions for managing multiple git repositories

# Repository locations
$script:mainRepo = "D:\CashHero-main"
$script:finApiRepo = "D:\cashhero-fin-api"
$script:commonApiRepo = "D:\cashhero-common-api"
$script:globalApiRepo = "D:\cashhero-global-api"

$script:repos = @(
    (Get-Item $script:mainRepo),
    (Get-Item $script:finApiRepo),
    (Get-Item $script:commonApiRepo),
    (Get-Item $script:globalApiRepo)
)

function Test-IfOnMainBranch { 
    return (git rev-parse --abbrev-ref HEAD) -eq 'main' 
}

function Update-All-Repos {
    foreach ($repo in $script:repos) {
        Update-Repo $repo
    }
    Set-Location $script:mainRepo
}

function Update-Repo {
    param(
        [System.IO.DirectoryInfo]$Repo = (Get-Item "D:\CashHero-main")
    )
    
    Set-Location $Repo.FullName

    if (Test-IfOnMainBranch) {
        Write-Host "Updating $($Repo.Name)..."
        git pull
    }
    else {
        Write-Warning "You are not on the main branch for $($Repo.Name)."
    }
}

# Function to list all current repo branches
function Show-CurrentBranches {
    # Print header with background color
    $headerText = "CURRENT BRANCHES"
    $padding = [Math]::Max(0, (60 - $headerText.Length) / 2)
    $paddedHeader = (" " * $padding) + $headerText + (" " * $padding)
    Write-Host $paddedHeader -BackgroundColor DarkMagenta -ForegroundColor White
    
    $results = $script:repos | ForEach-Object -ThrottleLimit 4 -Parallel {
        try {
            # Get current branch
            $branch = & git -C $_.FullName rev-parse --abbrev-ref HEAD 2>$null
            if ($LASTEXITCODE -ne 0 -or -not $branch) {
                return [PSCustomObject]@{
                    Name     = $_.Name
                    FullName = $_.FullName
                    Branch   = "unknown"
                    Status   = "error"
                    Success  = $false
                }
            }
            
            $branch = $branch.Trim()
            
            # Fetch latest changes to get accurate status
            & git -C $_.FullName fetch origin 2>$null
            
            # Check if remote branch exists
            $remoteBranch = "origin/$branch"
            $remoteExists = & git -C $_.FullName rev-parse --verify "$remoteBranch" 2>$null
            
            if ($LASTEXITCODE -ne 0) {
                $status = "no remote"
            }
            else {
                # Get commit counts
                $behindCount = & git -C $_.FullName rev-list --count "HEAD..$remoteBranch" 2>$null
                $aheadCount = & git -C $_.FullName rev-list --count "$remoteBranch..HEAD" 2>$null
                
                if ($LASTEXITCODE -ne 0) {
                    $status = "unknown"
                }
                elseif ([int]$behindCount -gt 0 -and [int]$aheadCount -gt 0) {
                    $status = "diverged (+$aheadCount/-$behindCount)"
                }
                elseif ([int]$behindCount -gt 0) {
                    $status = "behind (-$behindCount)"
                }
                elseif ([int]$aheadCount -gt 0) {
                    $status = "ahead (+$aheadCount)"
                }
                else {
                    $status = "up to date"
                }
            }
            
            [PSCustomObject]@{
                Name     = $_.Name
                FullName = $_.FullName
                Branch   = $branch
                Status   = $status
                Success  = $true
            }
        }
        catch {
            [PSCustomObject]@{
                Name     = $_.Name
                FullName = $_.FullName
                Branch   = "error"
                Status   = "error"
                Success  = $false
            }
        }
    }
    
    # Sort results to maintain original order and display
    foreach ($repo in $script:repos) {
        $result = $results | Where-Object { $_.FullName -eq $repo.FullName }
        if ($result) {
            # Determine colors based on branch and status
            $branchColor = if ($result.Branch -eq "main") { "Green" } else { "Cyan" }
            $statusColor = switch -Regex ($result.Status) {
                "up to date" { "Green" }
                "behind" { "Yellow" }
                "ahead" { "Blue" }
                "diverged" { "Magenta" }
                "no remote" { "Gray" }
                default { "Red" }
            }
            
            # Format and display
            Write-Host ("{0,-25}" -f $result.Name) -ForegroundColor White -NoNewline
            Write-Host ("{0,-15}" -f $result.Branch) -ForegroundColor $branchColor -NoNewline
            Write-Host (" {0}" -f $result.Status) -ForegroundColor $statusColor
        }
    }
}

function up { 
    Set-Location D:\ && docker compose up -d && Set-Location $script:mainRepo && wt -w 0 split-pane -- pwsh.exe -NoExit -Command Show-CurrentBranches && pnpm dev 
}

Export-ModuleMember -Function Test-IfOnMainBranch, Update-All-Repos, Update-Repo, Show-CurrentBranches, up
