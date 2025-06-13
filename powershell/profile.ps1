$isAIAgent = $false

try {
    $parentProcessId = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID" -ErrorAction Stop).ParentProcessId
    $parentProcess = Get-Process -Id $parentProcessId -ErrorAction Stop
    if ($parentProcess.ProcessName -like "*Cursor*") {
        $isAIAgent = $true
    }
} catch {
    $parentProcess = $null
}

if ($isAIAgent) {
    $PSStyle.OutputRendering = [System.Management.Automation.OutputRendering]::PlainText
    
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        try {
            oh-my-posh init pwsh --config '~\.chuya\oh-my-posh\pure.omp.json' | Invoke-Expression
        } catch {
            function prompt { "PS $($pwd.Path.Split('\')[-1])> " }
        }
    } else {
        function prompt { "PS $($pwd.Path.Split('\')[-1])> " }
    }
} else {
    if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
        oh-my-posh init pwsh --config '~\.chuya\oh-my-posh\chuya.omp.json' | Invoke-Expression
    }

    if (Get-Command PSReadLine -ErrorAction SilentlyContinue) {
        Import-Module PSReadLine
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
        Set-PSReadLineKeyHandler -Key Tab -Function Complete
    }
    
    function bash {
        & "C:\Program Files\Git\bin\bash.exe" --login -i
    }

    function nano {
        param([string]$file = "")
    
        if ($file -ne "") {
            $normalized = $file -replace '\\', '/'
            if ($normalized -match '^([A-Za-z]):') {
                $drive = $matches[1].ToLower()
                $path = $normalized.Substring(2)
                $bashPath = "/$drive$path"
            } else {
                $bashPath = $normalized
            }
            & "C:\Program Files\Git\bin\bash.exe" -c "nano '$bashPath'"
        } else {
            & "C:\Program Files\Git\bin\bash.exe" -c "nano"
        }
    }

    function p {
        param([string]$prf)
        $path = "~\.chuya\oh-my-posh\$prf.omp.json"
        if (Test-Path $path) {
            oh-my-posh init pwsh --config $path | Invoke-Expression
        } else {
            Write-Host "Profile '$prf' not found"
        }
    }
}