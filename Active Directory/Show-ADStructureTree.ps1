#Requires -Version 5.0
#Requires -Module @{ModuleName='ActiveDirectory';ModuleVersion='1.0.0.0'}
<#
.SYNOPSIS
Display the Active Directory structure ADObjects on the screen.

.DESCRIPTION
Display Active Directory structure ADObjects on the screen using Write-Host.
If capture is required, use ConvertTo-ADStructure cmdlet instead.

It is recommended to use the Get-ADStructure cmdlet to acquire the directory ADObject.

.PARAMETER ADObject
Defines the Active Directory ADObjects to traverse.

.PARAMETER NameColor
Defines the ConsoleColor to be used for the ADObjects name.

.PARAMETER ConnectorColor
Defines the ConsoleColor to be used for the ADObject connectors.

.PARAMETER TypeColor
Defines the ConsoleColor to be used for the ADObject type.

.EXAMPLE
PS:> $directory = Get-ADStructure
PS:> Show-ADStructureTree -ADObject $directory

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
    [PSCustomObject]$ADObject,

    [Parameter()]
    [ConsoleColor]$ConnectorColor = [ConsoleColor]::Green,

    [Parameter()]
    [ConsoleColor]$NameColor = [ConsoleColor]::Cyan,

    [Parameter()]
    [ConsoleColor]$TypeColor = [ConsoleColor]::DarkGray,

    [Parameter()]
    [Switch]$IncludeType
  )

  function ShowChildren {
    param(
      [PSCustomObject]$ADObject,
      [Int]$Depth = 0,
      [ConsoleColor]$ConnectorColor,
      [ConsoleColor]$NameColor,
      [ConsoleColor]$TypeColor,
      [Switch]$IncludeType
    )
  
    # Tree Characters
    $PIPE = [char]::ConvertFromUtf32(9474) # │
    $DASH = [char]::ConvertFromUtf32(9472) # ─
    $ANGLE = [char]::ConvertFromUtf32(9492) # └
    $TEE = [char]::ConvertFromUtf32(9500) # ├"
  
    if ($null -eq $ADObject -and $null -eq $ADObject.Children) {break}

    for ($i = 0; $i -lt $ADObject.Children.Count; $i++) {

      $connector = "$(($PIPE + '   ') * $Depth)"
      if ($i -eq ($ADObject.Children.Count - 1)) {
        $connector += "$ANGLE$($DASH *3)"
      }
      else {
        $connector += "$TEE$($DASH *3)"
      }

      Write-Host $connector -ForegroundColor $ConnectorColor -NoNewline
      Write-Host "$($ADObject.Children[$i].Name)" -ForegroundColor $NameColor -NoNewline
      Write-Host " $total" -ForegroundColor DarkGray -NoNewline
      if ($IncludeType) {
        Write-Host " ($($ADObject.Children[$i].Type))" -ForegroundColor $TypeColor -NoNewline
      }
      Write-Host ""

      $gcParams = @{
        ADObject       = $ADObject.Children[$i]
        Depth          = ($Depth + 1)
        ConnectorColor = $ConnectorColor
        NameColor      = $NameColor
      }
        
      if ($IncludeType) {
        $gcParams.Add("TypeColor", $TypeColor)
        $gcParams.Add("IncludeType", $IncludeType)
      }

      ShowChildren @gcParams
    }
  } ## END ShowChildren

  Write-Host "$($ADObject.Name)" -ForegroundColor $NameColor -NoNewline
  if ($IncludeType) {
    Write-Host " ($($ADObject.Type))" -ForegroundColor $TypeColor -NoNewline
  }
  Write-Host ""


  $childParams = @{
    ADObject       = $ADObject
    ConnectorColor = $ConnectorColor
    NameColor      = $NameColor
  }
  if ($IncludeType) {
    $childParams.Add("TypeColor", $TypeColor)
    $childParams.Add("IncludeType", $IncludeType)
  }
  ShowChildren @childParams
}