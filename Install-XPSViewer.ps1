function Add-XPSViewer {
    [CmdletBinding()]
    param (
        # Allows for a list of PC Names to check
        [Parameter (Mandatory = $True, ParameterSetName = "Single WS")]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName,

        # Allows for a list of WS. Must be a path
        [Parameter (Mandatory = $True, ParameterSetName = "List of WS")]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]
        $Path
    )
    
    begin {
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
    
    process {
        foreach ($computer in $computers)
        {
            Invoke-Command -ComputerName $computer -ScriptBlock {DISM /Online /Add-Capability /CapabilityName:XPS.Viewer~~~~0.0.1.0} 
        }
    }
    
    end {
    }
}












<#
$Computers = Get-Content -Path "C:\users\schnedler_e\desktop\xps\computers.txt"
foreach ($computer in $computers){
Invoke-Command -ComputerName $computer -ScriptBlock {DISM /Online /Add-Capability /CapabilityName:XPS.Viewer~~~~0.0.1.0} 
}
#>