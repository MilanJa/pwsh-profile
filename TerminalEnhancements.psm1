# Terminal Enhancements Module
# Contains terminal UI and enhancement functions

function Eza {
    [alias('ls')]
    param(
        [string]$Path = "."
    )
        
    eza.exe -lh -B --icons always --no-time  $Path 
}

Function Set-PredictionView {
    [cmdletbinding(SupportsShouldProcess)]
    [alias("spv", 'sview')]
    [OutputType("none")]
    Param(
        [Parameter(Position = 0, HelpMessage = "Specify the prediction style. Toggle will switch to the unused style.")]
        [ValidateSet("List", "InLine", "Toggle")]
        [string]$View = "Toggle",
        [switch]$Passthru
    )

    Try {
        Switch ($View) {
            "List" { $style = "ListView" }
            "Inline" { $style = "InLineView" }
            "Toggle" {
                Switch ((Get-PSReadLineOption).PredictionViewStyle) {
                    "InLineview" {
                        $style = "ListView"
                    }
                    "ListView" {
                        $style = "InLineView"
                    }
                    Default {
                        #fail safe action. This should never happen.
                        Write-Warning "Could not determine a view style. Are you running PSReadline v2.2.2 or later?"
                    }
                } #nested switch
            } #toggle
        } #switch view

        if ($style -AND ($PSCmdlet.ShouldProcess($style, "Set prediction view style"))) {
            Set-PSReadLineOption -PredictionViewStyle $style
            if ($Passthru) {
                Get-PredictionView
            }
        }
    } #try
    Catch {
        Write-Warning "There was a problem. Could not determine a view style. Are you running PSReadline v2.2.2 or later? $($_.exception.message)."
    }
}

# https://github.com/Canop/broot/issues/460#issuecomment-1303005689
Function br {
    $argss = $args -join ' '
    $cmd_file = New-TemporaryFile
  
    $process = Start-Process -FilePath 'broot.exe' `
        -ArgumentList "--outcmd $($cmd_file.FullName) $argss" `
        -NoNewWindow -PassThru -WorkingDirectory $PWD
  
    Wait-Process -InputObject $process #Faster than Start-Process -Wait
    If ($process.ExitCode -eq 0) {
        $cmd = Get-Content $cmd_file
        Remove-Item $cmd_file
        If ($null -ne $cmd) { Invoke-Expression -Command $cmd }
    }
    Else {
        Remove-Item $cmd_file
        Write-Host "`n" # Newline to tidy up broot unexpected termination
        Write-Error "broot.exe exited with error code $($process.ExitCode)"
    }
}

Export-ModuleMember -Function Eza, Set-PredictionView, br -Alias ls, spv, sview
