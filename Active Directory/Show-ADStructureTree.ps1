#Requires -Version 5.0
#Requires -Module @{ModuleName='ActiveDirectory';ModuleVersion='1.0.0.0'}
<#
.SYNOPSIS
Display the Active Directory structure nodes on the screen.

.DESCRIPTION
Display Active Directory structure nodes on the screen using Write-Host.
If capture is required, use ConvertTo-ADStructure cmdlet instead.

It is recommended to use the Get-ADStructure cmdlet to acquire the directory node.

.PARAMETER Node
Defines the Active Directory nodes to traverse.

.PARAMETER NodeColor
Defines the ConsoleColor to be used for the nodes name.

.PARAMETER ConnectorColor
Defines the ConsoleColor to be used for the node connectors.

.EXAMPLE
PS:> $directory = Get-ADStructure
PS:> ConvertTo-ADStructureTree -Node $directory

doamin (domainDNS)
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
function Show-ADStructureTree {
  [CmdletBinding()]
  param(
    [Parameter()]
    [PSCustomObject]$Node,

    [Parameter()]
    [ConsoleColor]$ConnectorColor = [ConsoleColor]::Cyan,

    [Parameter()]
    [ConsoleColor]$NodeColor = [ConsoleColor]::Yellow
  )

  function GetChildren {
    param(
      [PSCustomObject]$Node,
      [Int]$Spaces,
      [Switch]$IsRoot,
      [ConsoleColor]$ConnectorColor,
      [ConsoleColor]$NodeColor
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

        Write-Host $connector -NoNewline -ForegroundColor $ConnectorColor
        Write-Host "$($Node.Children[$i].Name) ($($Node.Children[$i].Type))" -ForegroundColor $NodeColor

        $gcParams = @{
          Node = $Node.Children[$i]
          Spaces = ($Spaces + 4)
          ConnectorColor = $ConnectorColor
          NodeColor = $NodeColor
        }
        GetChildren @gcParams
      }
    }
  }
  Write-Host "$($Node.Name) ($($Node.Type))" -ForegroundColor $NodeColor
  GetChildren -IsRoot $true -Node $Node -ConnectorColor $ConnectorColor -NodeColor $NodeColor
}