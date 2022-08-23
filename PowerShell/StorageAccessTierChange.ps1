Connect-AzAccount
#Initialize the following with your resource group, storage account, container, and blob names
#Set-AzureSubscription -SubscriptionName ContosoEngineering
$rgName = ""
$accountName = ""


#Select the storage account and get the context
$storageAccount = Get-AzStorageAccount -ResourceGroupName $rgName -Name $accountName
$ctx = $storageAccount.Context

$containers = Get-AzStorageContainer -Context $ctx

foreach($container in $containers)
{
    echo $container "started"
    
    #list the blobs in a container
    $blobs = Get-AzStorageBlob -Container $container.Name  -Context $ctx  
    foreach($blob in $blobs)  
    {  
        #if tier not equal "Archive"
        if($blob.AccessTier -eq "Archive"){
            
            $blob.Name>> d:\debug.txt
            $blob.ICloudBlob.SetStandardBlobTier("Hot")
        }
    }  
    echo $container "Completed"
}
