# Import the Active Directory module
Import-Module ActiveDirectory

# Define the domain
$domain = "moos.local"

# Define the Organizational Units to be created
$OUs = @(
    "Directie",
    "OU_DL",
    "Productie",
    "Logistiek",
    "Marketing",
    "Extern"
)

# Create Organizational Units
foreach ($OU in $OUs) {
    $ouPath = "OU=$OU,$domain"
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OU'")) {
        New-ADOrganizationalUnit -Name $OU -Path "DC=moos,DC=local"
        Write-Host "Created OU: $ouPath"
    } else {
        Write-Host "OU already exists: $ouPath"
    }
}

# Define users to be added
$users = @(
    @{Name="Angela Moos";GivenName="Angela";Surname="Moos";OU="Productie"},
    @{Name="Jeroen Moos";GivenName="Jeroen";Surname="Moos";OU="Directie"},
    @{Name="Hop Karlsberg";GivenName="Hop";Surname="Karlsberg";OU="Logistiek"},
    @{Name="Piet Huysenbrouwer";GivenName="Piet";Surname="Huysenbrouwer";OU="Marketing"},
    @{Name="Petra Alm";GivenName="Petra";Surname="Alm";OU="Extern"}
)

# Create users
foreach ($user in $users) {
    $ouPath = "OU=$($user.OU),DC=moos,DC=local"
    if (-not (Get-ADUser -Filter "Name -eq '$($user.Name)'")) {
        New-ADUser -Name $user.Name -GivenName $user.GivenName -Surname $user.Surname -UserPrincipalName "$($user.GivenName).$($user.Surname)@$domain" -SamAccountName "$($user.GivenName).$($user.Surname)" -Path $ouPath -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Enabled $true
        Write-Host "Created user: $($user.Name)"
    } else {
        Write-Host "User already exists: $($user.Name)"
    }
}

# Define global groups to be created
$groups = @(
    "GG_Directie",
    "GG_Onderzoek",
    "GG_Productie",
    "GG_Logistiek",
    "GG_Marketing",
    "GG_Extern",
    "GG_CEO",
    "GG_Secretaresse"
)

# Create global groups
foreach ($group in $groups) {
    if (-not (Get-ADGroup -Filter "Name -eq '$group'")) {
        New-ADGroup -Name $group -GroupScope Global -Path "DC=moos,DC=local"
        Write-Host "Created group: $group"
    } else {
        Write-Host "Group already exists: $group"
    }
}

# Add Angela Moos to the GG_Productie group
$angela = Get-ADUser -Filter "Name -eq 'Angela Moos'"
$group = Get-ADGroup -Filter "Name -eq 'GG_Productie'"

if ($angela -and $group) {
    Add-ADGroupMember -Identity $group -Members $angela
    Write-Host "Added Angela Moos to GG_Productie group"
} else {
    Write-Host "Error: Could not find Angela Moos or GG_Productie group"
}

# Import users from CSV file and create them
$csvPath = "C:\path\to\your\users.csv"
if (Test-Path $csvPath) {
    $csvUsers = Import-Csv -Path $csvPath
    foreach ($csvUser in $csvUsers) {
        $ouPath = "OU=$($csvUser.OU),DC=moos,DC=local"
        if (-not (Get-ADUser -Filter "Name -eq '$($csvUser.Name)'")) {
            New-ADUser -Name $csvUser.Name -GivenName $csvUser.GivenName -Surname $csvUser.Surname -UserPrincipalName "$($csvUser.GivenName).$($csvUser.Surname)@$domain" -SamAccountName "$($csvUser.GivenName).$($csvUser.Surname)" -Path $ouPath -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Enabled $true
            Write-Host "Created user from CSV: $($csvUser.Name)"
        } else {
            Write-Host "User from CSV already exists: $($csvUser.Name)"
        }
    }
} else {
    Write-Host "CSV file not found: $csvPath"
}

# Create Share folder and subfolders
$sharePath = "C:\Share"
$subFolders = @("Directie", "Logistiek", "Marketing", "Onderzoek", "Productie")

if (-not (Test-Path $sharePath)) {
    New-Item -Path $sharePath -ItemType Directory
    Write-Host "Created folder: $sharePath"
}

foreach ($folder in $subFolders) {
    $folderPath = Join-Path -Path $sharePath -ChildPath $folder
    $groupR = "DL_${folder}_R"
    $groupRWMX = "DL_${folder}_RWMX"
    $groupFC = "DL_${folder}_FC"

    if (-not (Test-Path $folderPath)) {
        New-Item -Path $folderPath -ItemType Directory
        Write-Host "Created folder: $folderPath"
    } else {
        Write-Host "Folder already exists: $folderPath"
    }

    # Create new groups for each folder in Shar
    foreach ($group in @($groupR, $groupRWMX, $groupFC)) {
        if (-not (Get-ADGroup -Filter "Name -eq '$group'")) {
            New-ADGroup -Name $group -GroupScope DomainLocal -Path "OU=OU_DL,DC=moos,DC=local"
            Write-Host "Created group: $group"
        } else {
            Write-Host "Group already exists: $group"
        }
    }

}



# Add testgroup and set permissions on Productie folder
$testGroupName = "testgroup"
if (-not (Get-ADGroup -Filter "Name -eq '$testGroupName'")) {
    New-ADGroup -Name $testGroupName -GroupScope Global -Path "DC=moos,DC=local"
    Write-Host "Created group: $testGroupName"
} else {
    Write-Host "Group already exists: $testGroupName"
}

$productiePath = Join-Path -Path $sharePath -ChildPath "Productie"
$acl = Get-Acl -Path $productiePath
$testGroupSid = (Get-ADGroup -Filter "Name -eq '$testGroupName'").SID
$permission = "ReadAndExecute"

$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($testGroupSid, $permission, "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.AddAccessRule($accessRule)
Set-Acl -Path $productiePath -AclObject $acl

Write-Host "Assigned read permissions to $testGroupName on $productiePath"
