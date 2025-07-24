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

# Function to show git status for all repos
function Show-AllStatus {
    Write-Host "GIT STATUS OVERVIEW" -BackgroundColor DarkBlue -ForegroundColor White
    Write-Host ""
    
    foreach ($repo in $script:repos) {
        Set-Location $repo.FullName
        $status = git status --porcelain
        $branch = git rev-parse --abbrev-ref HEAD
        
        Write-Host "📁 $($repo.Name)" -ForegroundColor Yellow
        Write-Host "   Branch: $branch" -ForegroundColor Cyan
        
        if ($status) {
            $status | ForEach-Object {
                $statusCode = $_.Substring(0, 2)
                $file = $_.Substring(3)
                $color = switch ($statusCode.Trim()) {
                    "M" { "Yellow" }     # Modified
                    "A" { "Green" }      # Added
                    "D" { "Red" }        # Deleted
                    "??" { "Gray" }      # Untracked
                    default { "White" }
                }
                Write-Host "   $statusCode $file" -ForegroundColor $color
            }
        }
        else {
            Write-Host "   ✅ Clean working directory" -ForegroundColor Green
        }
        Write-Host ""
    }
    Set-Location $script:mainRepo
}

# Function to stash changes in all repos
function Stash-AllRepos {
    param([string]$Message = "Auto-stash from PowerShell")
    
    Write-Host "Stashing changes in all repositories..." -ForegroundColor Yellow
    foreach ($repo in $script:repos) {
        Set-Location $repo.FullName
        $status = git status --porcelain
        if ($status) {
            Write-Host "Stashing changes in $($repo.Name)..." -ForegroundColor Cyan
            git stash push -m $Message
        }
        else {
            Write-Host "$($repo.Name): No changes to stash" -ForegroundColor Green
        }
    }
    Set-Location $script:mainRepo
}

# Function to pop stashed changes in all repos
function Pop-AllStashes {
    Write-Host "Popping stashes in all repositories..." -ForegroundColor Yellow
    foreach ($repo in $script:repos) {
        Set-Location $repo.FullName
        $stashList = git stash list
        if ($stashList) {
            Write-Host "Popping stash in $($repo.Name)..." -ForegroundColor Cyan
            git stash pop
        }
        else {
            Write-Host "$($repo.Name): No stashes to pop" -ForegroundColor Green
        }
    }
    Set-Location $script:mainRepo
}

# Function to switch branch in all repos
function Switch-AllBranches {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName
    )
    
    Write-Host "Switching to branch '$BranchName' in all repositories..." -ForegroundColor Yellow
    foreach ($repo in $script:repos) {
        Set-Location $repo.FullName
        Write-Host "Switching branch in $($repo.Name)..." -ForegroundColor Cyan
        
        # Check if branch exists locally
        $localBranch = git branch --list $BranchName
        if ($localBranch) {
            git checkout $BranchName
        }
        else {
            # Try to checkout from remote
            git checkout -b $BranchName origin/$BranchName 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Branch '$BranchName' not found in $($repo.Name)"
            }
        }
    }
    Set-Location $script:mainRepo
    Show-CurrentBranches
}

# Function to run a git command in all repos
function Invoke-GitInAllRepos {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GitCommand
    )
    
    Write-Host "Running 'git $GitCommand' in all repositories..." -ForegroundColor Yellow
    foreach ($repo in $script:repos) {
        Set-Location $repo.FullName
        Write-Host "📁 $($repo.Name):" -ForegroundColor Cyan
        Invoke-Expression "git $GitCommand"
        Write-Host ""
    }
    Set-Location $script:mainRepo
}

# Function to show last commit in each repo
function Show-LastCommits {
    Write-Host "LAST COMMITS" -BackgroundColor DarkGreen -ForegroundColor White
    Write-Host ""
    
    foreach ($repo in $script:repos) {
        Set-Location $repo.FullName
        $lastCommit = git log -1 --pretty=format:"%h - %an, %ar : %s"
        Write-Host "📁 $($repo.Name)" -ForegroundColor Yellow
        Write-Host "   $lastCommit" -ForegroundColor White
        Write-Host ""
    }
    Set-Location $script:mainRepo
}

# Function to open all repos in VS Code
function Open-AllInVSCode {
    foreach ($repo in $script:repos) {
        Write-Host "Opening $($repo.Name) in VS Code..." -ForegroundColor Cyan
        code $repo.FullName
    }
}

# Function to check for uncommitted changes across all repos
function Test-HasUncommittedChanges {
    $hasChanges = $false
    Write-Host "CHECKING FOR UNCOMMITTED CHANGES" -BackgroundColor DarkRed -ForegroundColor White
    Write-Host ""
    
    foreach ($repo in $script:repos) {
        Set-Location $repo.FullName
        $status = git status --porcelain
        if ($status) {
            $hasChanges = $true
            Write-Host "⚠️  $($repo.Name) has uncommitted changes" -ForegroundColor Red
        }
        else {
            Write-Host "✅ $($repo.Name) is clean" -ForegroundColor Green
        }
    }

    Set-Location $script:mainRepo
    return $hasChanges
}

# Function to create and switch to a new branch in all repos
function New-BranchInAllRepos {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName
    )
    
    Write-Host "Creating and switching to branch '$BranchName' in all repositories..." -ForegroundColor Yellow
    foreach ($repo in $script:repos) {
        Set-Location $repo.FullName
        Write-Host "Creating branch in $($repo.Name)..." -ForegroundColor Cyan
        git checkout -b $BranchName
    }
    Set-Location $script:mainRepo
    Show-CurrentBranches
}

# Quick aliases for common operations
function gsa { Show-AllStatus }
function gsc { Show-CurrentBranches }
function glc { Show-LastCommits }

function up { 
    Set-Location D:\ && docker compose up -d && Set-Location $script:mainRepo && wt -w 0 split-pane -- pwsh.exe -NoExit -Command Show-CurrentBranches && pnpm dev 
}

Export-ModuleMember -Function Test-IfOnMainBranch, Update-All-Repos, Update-Repo, Show-CurrentBranches, Show-AllStatus, Stash-AllRepos, Pop-AllStashes, Switch-AllBranches, Invoke-GitInAllRepos, Show-LastCommits, Open-AllInVSCode, Test-HasUncommittedChanges, New-BranchInAllRepos, gsa, gsc, glc, up
