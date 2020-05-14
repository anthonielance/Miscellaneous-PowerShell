#Requires -Version 5.1
#Requires -Module @{ ModuleName = 'SharePointPnPPowerShellOnline'; ModuleVersion = '3.21.2005.1' }

using namespace Microsoft.SharePoint.Client

function Copy-PnPListItemAttachment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ListItem]$SourceItem,

        [Parameter(Mandatory)]
        [ListItem]$TargetItem)
        
    begin {
        # Set current context to the source item context for use with the Get-PnpFile cmdlet.
        $incomingContext = Get-PnPContext
        if ($incomingContext -ne $SourceItem.Context) {
            Write-Verbose "Changing context to source items context"
            Set-PnPContext -Context $SourceItem.Context
        }
    }

    process {
        
        try {
            
            # Get all attachments from source  
            [array]$attachments = Get-PnPProperty -ClientObject $SourceItem -Property "AttachmentFiles"
            Write-Verbose "[$($SourceItem['UniqueId'])] Found ($($attachment.Count) attachments"

            $attachments | ForEach-Object {  
                
                # Retreive file and create stream
                $file = Get-PnPFile -Url $_.ServerRelativeUrl | Out-Null
                $binaryStream = [System.IO.BinaryReader]::new($File.OpenBinaryStream().Value)
                
                # Add attachment to target item  
                $attachmentInfo = [Microsoft.SharePoint.Client.AttachmentCreationInformation]::new()
                $attachmentInfo.FileName = $_.FileName
                $attachmentInfo.ContentStream = $binaryStream
                $TargetItem.AttachmentFiles.add($AttachmentInfo) | Out-Null
                $TargetItem.Context.ExecuteQuery()

                Write-Verbose "[$($SourceItem['UniqueId'])] Added attachment '$($file.Name)'"
            }  
        }  
        catch {
            Write-Warning "[$($SourceItem['UniqueId'])] Failed attaching '$($file.Name)'"
            Write-Warning "[$($SourceItem['UniqueId'])] $($_.Exception.Message)"
        }
        finally {
            $binaryStream.Close()
        }
        
    }

    end {
        # Reset context
        if ($incomingContext -ne (Get-PnpContext)) {
            Write-Verbose "Resetting current context"
            Set-PnPContext -Context $incomingContext
        }
    }
}