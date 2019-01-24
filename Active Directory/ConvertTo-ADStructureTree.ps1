#Requires -Version 5.0
#Requires -Module @{ModuleName='ActiveDirectory';ModuleVersion='1.0.0.0'}
<#
.SYNOPSIS
Converts Active Directory structure nodes to text.

.DESCRIPTION
Converts Active Directory structure nodes to text.
This can be used to export the directory structure to an external file.

It is recommended to use the Get-ADStructure cmdlet to acquire the directory node.

.PARAMETER Node
Defines the Active Directory nodes to traverse.

.EXAMPLE
PS:> $directory = Get-ADStructure
PS:> ConvertTo-ADStructureTree -Node $directory

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
    [PSCustomObject]$Node
  )

  function GetChildren {
    param(
      [PSCustomObject]$Node,
      [Int]$Spaces,
      [Switch]$IsRoot
    )
  
    begin {
      # Tree Characters
      $pipe = [char]::ConvertFromUtf32(9474) # │
      $dash = [char]::ConvertFromUtf32(9472) # ─
      $angle = [char]::ConvertFromUtf32(9494) # └
      $tee = [char]::ConvertFromUtf32(9500) # ├"
    }
  
    process {
      
      if ($null -eq $Node -and $null -eq $Node.Children) {break}

      for ($i = 0; $i -lt $Node.Children.Count; $i++) {
        $connector = ""
        if ($i -eq ($Node.Children.Count - 1)) {
          if ($IsRoot) {
            $connector = "$(' ' * ($Spaces-1))$angle$($dash *3)"
          }
          else {
            $connector = "$pipe$(' ' * ($Spaces-1))$angle$($dash *3)"
          }
        }
        else {
          if ($IsRoot) {
            $connector = "$(' ' * ($Spaces-1))$tee$($dash *3)"
          }
          else {
            $connector = "$pipe$(' ' * ($Spaces-1))$tee$($dash *3)"
          }
        }

        Write-Output "$connector$($Node.Children[$i].Name) ($($Node.Children[$i].Type))"

        $gcParams = @{
          Node           = $Node.Children[$i]
          Spaces         = ($Spaces + 4)
          ConnectorColor = $ConnectorColor
          NameColor      = $NameColor
        }
        GetChildren @gcParams
      }
    }
  }
  Write-Output "$($Node.Name) ($($Node.Type))"
  GetChildren -IsRoot $true -Node $Node
}