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
    $Credential
  )

  $parentRawParams = @{
    Identity = $SearchBase
  }
  if ($Credential) { $parentRawParams.Add("Credential", $Credential) }
  $parentRawNode = Get-ADObject @parentRawParams

  if ($null -eq $parentRawNode) {break}

  $childRawParams = @{
    SearchBase  = $parentRawNode.DistinguishedName
    SearchScope = "OneLevel"
    LDAPFilter  = "(|(objectClass=domainDNS)(objectClass=user)(objectClass=computer)(objectClass=group)(objectClass=container)(objectClass=organizationalUnit))"
  }
  if ($Credential) { $childRawParams.Add("Credential", $Credential) }
  $childRawNodes = Get-ADObject @childRawParams

  $childNodes = $childRawNodes |
    ForEach-Object {
    $childParams = @{
      SearchBase = $_.DistinguishedName
    }
    if ($Credential) { $childParams.Add("Credential", $Credential)}
    Get-ADStructure @childParams
  }


  $TotalUsers      = (($childNodes | Where-Object Type -eq 'user'               | Measure-Object).Count + ($childNodes.Children | Where-Object Type -eq 'user'               | Measure-Object).Count)
  $TotalComputers  = (($childNodes | Where-Object Type -eq 'computer'           | Measure-Object).Count + ($childNodes.Children | Where-Object Type -eq 'computer'           | Measure-Object).Count)
  $TotalGroups     = (($childNodes | Where-Object Type -eq 'group'              | Measure-Object).Count + ($childNodes.Children | Where-Object Type -eq 'group'              | Measure-Object).Count)
  $TotalOUs        = (($childNodes | Where-Object Type -eq 'organizationalUnit' | Measure-Object).Count + ($childNodes.Children | Where-Object Type -eq 'organizationalUnit' | Measure-Object).Count)
  $TotalContainers = (($childNodes | Where-Object Type -eq 'container'          | Measure-Object).Count + ($childNodes.Children | Where-Object Type -eq 'container'          | Measure-Object).Count)

  [PSCustomObject]@{
    Name              = $parentRawNode.Name
    Type              = $parentRawNode.ObjectClass
    DistinguishedName = $parentRawNode.DistinguishedName
    Children          = $childNodes
    Totals            = [PSCustomObject]@{
      Users               = $TotalUsers
      Computers           = $TotalComputers
      Groups              = $TotalGroups
      OrganizationalUnits = $TotalOUs
      Containers          = $TotalContainers 
    }
  }
}