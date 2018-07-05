    function Get-ADGroupMembership 
    {
          <#
            .SYNOPSIS
            Gets all populated AD Groups recursively from a target OU, then populates a .csv with the groupnames, members, and membertype.
            .DESCRIPTION
            Gets all populated AD Groups recursively from a target OU, then populates a .csv with the groupnames, members, and membertype.
            .EXAMPLE
            Get-ADGroupMembership -Searchbase "OU=Groups,DC=Example,DC=.com"
            Gets all groups and members within the Groups OU, and exports them to a .csv
            #>
        [CmdletBinding()]
        param 
        (
            [Parameter (Mandatory = $true,
            Helpmessage= "Enter Fullly Qualified Path for searchbase (ie. OU=X,DC=X)")] 
            [string] $Computers
            #Must use Fullly Qualified Path (OU=X,DC=X)   
        )
        
        begin 
        {
        #Getting the documents folder for future ues. Helps avoid having to guess what drive things are in
          $DOCUMENTS = [environment]::getfolderpath("mydocuments")
          #If the file exists already, remove it. Done due to Export-CSV using Append later in function
          Write-Verbose -Message "Checking for the existance of $Documents\GroupMembers.csv"
          If((Test-Path "$Documents\GroupMembers.csv") -eq $true)
          {
              Write-Verbose -Message "File found! Removing to avoid data errors"
              Remove-Item "$Documents\GroupMembers.csv"
          }
          Write-Verbose "$Documents\Groupmembers.csv not found or removed! Continuing..."
        }
        
        process 
        {
            Write-Verbose -Message "Getting Groups from $SearchBase"
            $Groups = Get-ADGroup -Properties Name -Filter * -SearchBase $SearchBase
            Write-Verbose -Message "Getting Members from each group, then exporting to .csv."
            ForEach ($Group in $Groups) 
            {
                # Set the group name
                $Hashtable = @{GroupName = $Group.Name}
                $Members = Get-ADGroupMember -Identity $group -ErrorAction SilentlyContinue
                    ForEach ($Member in $Members) 
                    {
                        <# 
                            Going through every group member, insert the name in the hashtable and output
                            one object per member, containing groupname, membername, and type (user, group, workstation)
                            Data is then added to a .csv file.
                        #>
                        $Hashtable['Member'] = $Member.Name
                        $Hashtable['Type'] = $Member.ObjectClass
                        [PsCustomObject] $Hashtable | Export-Csv -path "$DOCUMENTS\Groupmembers.csv" -Append -NoTypeInformation
                    }
            }

        }
        
        end 
        {
        #Opens created .csv with default program
           Write-Verbose -Message "Opening datafile"
           Invoke-Item -Path "$DOCUMENTS\GroupMembers.csv"
        }
    }

    