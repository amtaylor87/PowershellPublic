function Add-XPSViewer 
{
    [CmdletBinding()]
    param 
    (
        # Allows for a list of PC Names to check
        [Parameter (Mandatory = $True, ParameterSetName = "Single WS")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName,

        # Allows for a list of WS. Must be a path
        [Parameter (Mandatory = $True, ParameterSetName = "List of WS")]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $Path,

        #Switch to test for WinRM
        [switch]
        $TestRM
    )
    
    begin 
    {
        $Online = New-Object System.Collections.Generic.List[System.Object]
        $Offline = New-Object System.Collections.Generic.List[System.Object]
        $NoRM = New-Object System.Collections.Generic.List[System.Object]
        if($ComputerName -ne $Null)
        {
            Write-Debug "Preparing to process workstations"
            $Computers = $ComputerName
        }
        elseif($Path -ne $Null){
            Write-Debug "Coverting List to Array"
            $Computers = Get-Content -Path $Path
        }
        else{
            throw "Unexpected error: No values found."
            exit
        }
    }

    process 
    {
        #Test to see which workstations are offline
        foreach ($computer in $computers)
        {
            if (-not (Test-Connection -ComputerName $computer -ErrorAction SilentlyContinue -Count 1))
            {
                $Offline.add($Computer)
            }
            else 
            {
                $Online.add($Computer)
            }
        }

        #Then, test the online computers to ensure that WinRM is enabled, if switch is enabled
        if($TestRM)
        {
            foreach ($O in $Online)
            {
                try
                {
                    Test-WSMan -ComputerName $O
                }
                catch
                {
                    $NoRM.add($O)
                    $Online.remove($O)
                }

            }
        }
        #Add XPS Viewer to the eligible machines
        foreach ($WS in $Online)
        {
            Invoke-Command -ComputerName $WS -ScriptBlock {DISM /Online /Add-Capability /CapabilityName:XPS.Viewer~~~~0.0.1.0}
            
        }
    }
    end 
    {
        $Offline | Out-File "$home\Documents\Offline.txt"
        Invoke-Item "$home\Documents\Offline.txt"
        if($TestRM)
        {
            $NoRm | Out-File "$home\Documents\NoRM.txt"
            Invoke-Item "$home\Documents\NoRM.txt"
        }
    }
}