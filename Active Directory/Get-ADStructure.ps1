#Requires -Version 5.0
#Requires -Module @{ModuleName='ActiveDirectory';ModuleVersion='1.0.0.0'}
<#
.SYNOPSIS
Get the structure of nodes that make up the Active Directory hierarchy.

.DESCRIPTION
Get the structure of nodes that make up the Active Directory hierarchy.
It is limited to the following directory objects.

- User
- Computer
- Group
- Container
- OrganizationalObjects

.PARAMETER SearchBase
Defines the start of the directory search.

.PARAMETER Credential
Credenitals to be used when performing the search.

.EXAMPLE
PS:> $directory = Get-ADStructure -SearchBase "OU=Departments,DC=domain,DC=com"

.NOTES
Author: Anthonie Lance
Date: 2019-01-24
#>
function Get-ADStructure {
  [CmdletBinding()]
  param(
    # Parameter help description
    [Parameter()]
    [String]
    $SearchBase = (Get-ADRootDSE).defaultNamingContext,

    [Parameter()]
    [PSCredential]
    $Credential,

    [Parameter()]
    [ValidateSet("Computer", "Container", "Group", "Person")]
    [string[]]$IncludeType
  )

  Write-Progress -Activity "Getting AD Structure..." -Status $SearchBase

  ## Getting current Active Directory object
  $currentObjectParams = @{
    Identity = $SearchBase
  }
  if ($Credential) { $currentObjectParams.Add("Credential", $Credential) }
  $currentObject = Get-ADObject @currentObjectParams -Properties ObjectCategory

  if ($null -eq $currentObject) {break}

  ## Getting current Active Directory object children
  $childRawObjectParams = @{
    SearchBase  = $currentObject.DistinguishedName
    SearchScope = "OneLevel"
    LDAPFilter  = "(|(objectCategory=DomainDNS)(objectCategory=OrganizationalUnit))"
  }
  if ($Credential) { $childRawObjectParams.Add("Credential", $Credential) }
  if ($IncludeType.Count -gt 0) {
    $categories = $IncludeType | ForEach-Object {"(objectCategory=$($_.ToLower()))" }
    $filter = [String]::Join("", $categories)
    $childRawObjectParams.LDAPFilter = "(|(objectCategory=DomainDNS)(objectCategory=OrganizationalUnit)" + $filter + ")"
  }

  $childRawObjects = Get-ADObject @childRawObjectParams

  ## Getting current Active Directory object children children
  $childObjects = $childRawObjects |
    ForEach-Object {
    $childObjectParams = @{
      SearchBase = $_.DistinguishedName
    }
    if ($IncludeType) { $childObjectParams.Add("IncludeType", $IncludeType)}
    if ($Credential) { $childObjectParams.Add("Credential", $Credential)}
    Get-ADStructure @childObjectParams
  }

  ## Calculating Active Directory statistics
  $Totals = [PSCustomObject]@{}
  
  $TotalOUs = (
    ($childObjects | Where-Object Type -eq "OrganizationalUnit" | Measure-Object).Count +
    ($childObjects.Children | Where-Object Type -eq "OrganizationalUnit" | Measure-Object).Count
  )
  Add-Member -InputObject $Totals -MemberType NoteProperty -Name "OrganizationalUnit" -Value $TotalOUs
  
  foreach($type in $IncludeType) {
    $TotalType = (($childObjects | Where-Object Type -eq $type | Measure-Object).Count + ($childObjects.Children | Where-Object Type -eq $type | Measure-Object).Count)
    Add-Member -InputObject $Totals -MemberType NoteProperty -Name $type -Value $TotalType
  }  

  ## Writing Active Directory statistics to pipeline
  [PSCustomObject]@{
    Name              = $currentObject.Name
    Type              = (($currentObject.ObjectCategory -replace "(CN=)(.*?),.*",'$2') -replace "-", '')
    DistinguishedName = $currentObject.DistinguishedName
    Children          = [array]$childObjects
    Totals            = $Totals
  }
}