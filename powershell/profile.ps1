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
    function prompt { "PS $($pwd.Path.Split('\')[-1])> " }
} else {
    Import-Module PSReadLine
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
    
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
}