<#
.SYNOPSIS
    Installs XPS Viewer on target Windows workstations
.DESCRIPTION
    Windows 10 Build 1803 does not have XPS Viewer enabled. This script allows for users
    to enable XPS Viewer on a single workstation or a list of workstations
.EXAMPLE
    PS C:\> Add-XPSViewer -ComputerName Client1
    Tests to ensure Client1 is online, then enables XPS Viewer
.EXAMPLE
    PS C:\> Add-XPSViewer -Path "C:\WS\ClientList.txt"
    Tests connectivitiy of all WS in list, then enables the XPS Viewer on all online WS. Displays a list of all offline workstations
.EXAMPLE
    PS C:\> Add-XPSViewer -Path "C:\WS\ClientList.txt" -TestRM
    Tests connectivitiy of all WS in list, then enables the XPS Viewer on all online WS. Displays a list of all offline workstations. Also tests for WinRM emabled WS.
.INPUTS
    -ComputerName
    -Path
    -WSMan(Optional)
.OUTPUTS
   Offline.txt--All WS that failed Test-Connection
   (Optional)NoRM.txt - All Online WS that WinRM failed
.NOTES
    Requires that WinRM is enabled on target WS.
#>
function Add-XPSViewer 
{
    [CmdletBinding()]
    param 
    (
        # Allows for a list of PC Names to enable XPS Viewer
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
        #Casting arrays that will be used later in script
        $Online = New-Object System.Collections.Generic.List[System.Object]
        $Offline = New-Object System.Collections.Generic.List[System.Object]
        $NoRM = New-Object System.Collections.Generic.List[System.Object]
        #Preparing input for script below.
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
            Write-Verbose "Testing to see if $Computer is online"
            if (-not (Test-Connection -ComputerName $computer -ErrorAction SilentlyContinue -Count 1))
            {
                Write-Verbose "$Computer is offline, removing from execution list"
                $Offline.add($Computer)
            }
            else 
            {
                Write-Verbose "$Computer is online"
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
                    Write-Verbose "Testing for WinRM on $O"
                    Test-WSMan -ComputerName $O
                }
                catch
                {
                    Write-Verbose "WinRM not enabled on $O, removeing from list"
                    $NoRM.add($O)
                    $Online.remove($O)
                }

            }
        }
        #Add XPS Viewer to the eligible machines
        foreach ($WS in $Online)
        {
            Write-verbose "Enabling XPS Viewer on $WS"
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