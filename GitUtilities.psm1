# Git Utilities Module
# Contains Git-related helper functions

function ghelp {
    Get-Content -Path "~/git-aliases.txt" | Invoke-Fzf
}

function gs {
    git branch 
    | ForEach-Object { $_ -replace '^\*?\s+', '' } 
    | Invoke-Fzf -Preview 'git log --oneline --decorate --color=always {+}' -PreviewWindow 'right:60%' -Layout 'reverse' 
    | ForEach-Object {
        git switch $_
    }
}

Export-ModuleMember -Function ghelp, gs
