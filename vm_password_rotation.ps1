$Env:OP_SERVICE_ACCOUNT_TOKEN = "xxx onepassword token xxx"


# Function to generate a random password
function Generate-RandomPassword {
    $uppercaseChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $lowercaseChars = 'abcdefghijklmnopqrstuvwxyz'
    $numberChars = '0123456789'
    $specialChars = '!@#$%^&*()+=?<>'

    $password = ""

    # Add at least one uppercase letter
    $password += $uppercaseChars[(Get-Random -Minimum 0 -Maximum $uppercaseChars.Length)]

    # Add at least one lowercase letter
    $password += $lowercaseChars[(Get-Random -Minimum 0 -Maximum $lowercaseChars.Length)]

    # Add at least one number
    $password += $numberChars[(Get-Random -Minimum 0 -Maximum $numberChars.Length)]

    # Add at least one special character
    $password += $specialChars[(Get-Random -Minimum 0 -Maximum $specialChars.Length)]

    # Add additional random characters to meet desired length (12 characters)
    $remainingLength = 12 - $password.Length
    $randomChars = $uppercaseChars + $lowercaseChars + $numberChars + $specialChars 
    for ($i = 0; $i -lt $remainingLength; $i++) {
        $password += $randomChars[(Get-Random -Minimum 0 -Maximum $randomChars.Length)]
    }

    # Shuffle the characters in the password
    $passwordArray = $password.ToCharArray() | Sort-Object {Get-Random}
    $password = -join $passwordArray

    return $password
}



Set-AzContext -Subscriptionid "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"


$vmlist = Get-AzVM 
foreach ($vm in $vmlist) {
    # Generate a random password
    $randomPassword = Generate-RandomPassword
    if ($vm.osprofile.Adminusername) {
        Write-Output "$($vm.Name) has $($vm.osprofile.Adminusername) as the admin username."
        az vm user update --resource-group $vm.ResourceGroupName --name $vm.name --username  $vm.osprofile.Adminusername --password $randomPassword
        Write-Output "$randomPassword"
        $secretItem= op item get $vm.Name --vault 'Support Team'
        if ($secretItem){
            op item edit $vm.Name --vault 'Support Team' password="$randomPassword" 
        }
        else{
            
            op item create  --title $vm.Name --category server --vault 'Support Team' password[password]="$randomPassword" username[userame]="$($vm.osprofile.Adminusername)" 
        }
    }
    else {
        Write-Output "$($vm.Name) has blank admin username. Hence fetching from vault"
        $secretItem = op item get $vm.Name --vault 'Support Team' --format json
        if ($secretItem){
            $itemData = $secretItem | ConvertFrom-Json
            $username = ($itemData.fields | Where-Object { $_.label -eq "username" }).value
            az vm user update --resource-group $vm.ResourceGroupName --name $vm.name --username $username --password $randomPassword
            op item edit $vm.Name --vault 'Support Team' password="$randomPassword"
        }
        else{
            az vm user update --resource-group $vm.ResourceGroupName --name $vm.name --username "adminuser" --password $randomPassword
            op item create  --title $vm.Name --category server --vault 'Support Team' password[password]="$randomPassword" username[userame]="adminuser"
        }

    }
}
