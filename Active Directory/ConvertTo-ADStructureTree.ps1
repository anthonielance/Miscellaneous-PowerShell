#Requires -Version 5.0
#Requires -Module @{ModuleName='ActiveDirectory';ModuleVersion='1.0.0.0'}
<#
.SYNOPSIS
Converts Active Directory structure ADObjects to text.

.DESCRIPTION
Converts Active Directory structure ADObjects to text.
This can be used to export the directory structure to an external file.

It is recommended to use the Get-ADStructure cmdlet to acquire the directory ADObject.

.PARAMETER ADObject
Defines the Active Directory ADObjects to traverse.

.PARAMETER IncludeType
When selected the output will include the Active Directorys object type

.EXAMPLE
PS:> $directory = Get-ADStructure
PS:> ConvertTo-ADStructureTree -ADObject $directory

doamin
├───Administration (organizationalUnit)
│   └───Presidents Office (group)
├───Built-In Users & Groups (container)
├───Department (organizationUnit)
│   └───Human Resources (organizationalUnit)
│       ├───Jane Doe (user)
│       ├───Sam Jones (user)
│       ├───Payroll (group)
.NOTES
Author: Anthonie Lance
Date: 2019-01-24
#>

function ConvertTo-ADStructureTree {
  [CmdletBinding()]
  param(
    [Parameter()]
    [PSCustomObject]$ADObject,

    [Parameter()]
    [Switch]$IncludeType
  )

  function GetChildren {
    param(
      [PSCustomObject]$ADObject,
      [Int]$Depth = 0,
      [Switch]$IncludeType
    )
  
    begin {
      # Tree Characters
      $PIPE = [char]::ConvertFromUtf32(9474) # │
      $DASH = [char]::ConvertFromUtf32(9472) # ─
      $ANGLE = [char]::ConvertFromUtf32(9492) # └
      $TEE = [char]::ConvertFromUtf32(9500) # ├"
    }
  
    process {
      
      if ($null -eq $ADObject -and $null -eq $ADObject.Children) {break}

      for ($i = 0; $i -lt $ADObject.Children.Count; $i++) {
        
        $connector = "$(($PIPE + '   ') * $Depth)"

        if ($i -eq ($ADObject.Children.Count - 1)) {
          $connector += "$ANGLE$($DASH *3)"
        } else {
          $connector += "$TEE$($DASH *3)"
        }

        if ($IncludeType) {
          Write-Output "$connector$($ADObject.Children[$i].Name) ($($ADObject.Children[$i].Type))"
        }
        else {
          Write-Output "$connector$($ADObject.Children[$i].Name)"
        }        

        $gcParams = @{
          ADObject = $ADObject.Children[$i]
          Depth   = ($Depth + 1)
        }
        if ($IncludeType) {
          $gcParams.Add("IncludeType", $IncludeType)
        }
        GetChildren @gcParams
      }
    }
  }

  $childParams = @{
    ADObject = $ADObject
  }
  if ($IncludeType) {
    Write-Output "$($ADObject.Name) ($($ADObject.Type))"
    $childParams.Add("IncludeType", $IncludeType)
  } else {
    Write-Output "$($ADObject.Name)"
  }

  GetChildren @childParams
}