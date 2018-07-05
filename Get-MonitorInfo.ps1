$Path = Read-Host "Enter path to computers"
$Computers = Get-Content -Path "$Path"
$Online = @()
$Offline = @()
    #Getting the documents folder for future ues. Helps avoid having to guess what drive things are in
      $DOCUMENTS = [environment]::getfolderpath("mydocuments")
      #If the file exists already, remove it. Done due to Export-CSV using Append later in function
      Write-Verbose -Message "Checking for the existance of $Documents\Monitors.csv"
      If((Test-Path "$Documents\Monitors.csv") -eq $true)
      {
          Write-Verbose -Message "File found! Removing to avoid data errors"
          Remove-Item "$Documents\Monitors.csv"
      }
      Write-Verbose "$Documents\Monitors.csv not found or removed! Continuing..."
      #Test to see if computer is reachable on network, and sorts Online and Offline Units
      foreach ($Computer in $Computers)
      {
        if((Test-Connection -ComputerName $Computer -Count 1 -Quiet) -eq $true)
        {
          $Online += $Computer
        }
        else
        {
          $Offline += $Computer
        }
      }
      #Get Monitor Info from Online units
      foreach ($O in $Online)
        {
          Get-WmiObject WmiMonitorID -Namespace root\wmi -computername $O|
            Select-Object PSComputerName,
                  @{n="Model";e={[System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName -ne 00)}},
                  @{n="Serial Number";e={[System.Text.Encoding]::ASCII.GetString($_.SerialNumberID -ne 00)}} |
            Export-csv -Path "$Documents\Monitors.csv" -NoTypeInformation -Append
        }
    
    #Opens created .csv with default program
       Write-Verbose -Message "Opening datafile"
       Invoke-Item -Path "$DOCUMENTS\Monitors.csv"
       $Offline | Export-Csv -Path "$Documents\OfflinePCs.csv" -NoTypeInformation
       Invoke-Item -Path "$Documents\OfflinePCs.csv"
