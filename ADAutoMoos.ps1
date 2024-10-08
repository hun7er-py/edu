	# Import the Active Directory module
	Import-Module ActiveDirectory

	# Define the domain
	$domain = "moos.local"

	# Define the Organizational Units to be created
	$OUs = @(
		"Directie",
		"Onderzoek",
		"Productie",
		"Logistiek",
		"Marketing",
		"Users",
		"OU_DL"
	)

	# Define users to be added
	$users = @(
		@{Name="Angela Moos";GivenName="Angela";Surname="Moos";OU="Productie"},
		@{Name="Jeroen Moos";GivenName="Jeroen";Surname="Moos";OU="Directie"},
		@{Name="Hop Karlsberg";GivenName="Hop";Surname="Karlsberg";OU="Logistiek"},
		@{Name="Piet Huysenbrouwer";GivenName="Piet";Surname="Huysenbrouwer";OU="Marketing"},
		@{Name="Petra Alm";GivenName="Petra";Surname="Alm";OU="Extern"}
	)

	# Define global groups to be created
	$groups = @(
		"GG_Directie",
		"GG_Onderzoek",
		"GG_Productie",
		"GG_Logistiek",
		"GG_Marketing",
		"GG_Users",
		"GG_CEO",
		"GG_Secretaresse"
	)

	New-ADOrganizationalUnit -Name "MOOS" -Path "DC=moos,DC=local"

	# Create Organizational Units
	foreach ($OU in $OUs) {
		$ouPath = "OU=$OU,$domain"
		if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$OU'")) {
			New-ADOrganizationalUnit -Name $OU -Path "OU=MOOS,DC=moos,DC=local"
			Write-Host "Created OU: $ouPath"
		} else {
			Write-Host "OU already exists: $ouPath"
		}
	}



	# Create users
	foreach ($user in $users) {
		try{
			$ouPath = "OU=$($user.OU),DC=moos,DC=local"
			if (-not (Get-ADUser -Filter "Name -eq '$($user.Name)'")) {
				New-ADUser -Name $user.Name -GivenName $user.GivenName -Surname $user.Surname -UserPrincipalName "$($user.GivenName).$($user.Surname)@$domain" -SamAccountName "$($user.GivenName).$($user.Surname)" -Path $ouPath -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Enabled $true
				Write-Host "Created user: $($user.Name)"
			} 
			else{
				Write-Host "User already exists: $($user.Name)"
			}
		}
		catch {
			# Output error message
			Write-Host "Failed to create user: $($user.UserName)"
			Write-Host $_.Exception.Message
		}
	}



	# Create global groups
	$i = 0
	foreach ($group in $groups) {
		Write-Host $i
		try{
			if ((-not (Get-ADGroup -Filter "Name -eq '$group'")) -and ($i -lt 5)) {
				
					$ou=$OUs[$i]
					Write-Host $ou
					New-ADGroup -Name $group -GroupScope Global -Path "OU=$ou,OU=MOOS,DC=moos,DC=local"
					Write-Host "Created group: $group"
				
			} else {
				New-ADGroup -Name $group -GroupScope Global -Path "OU=MOOS,DC=moos,DC=local"
				Write-Host "Created group: $group"
				Write-Host "Group already exists: $group"
			}
		}
		catch{
			Write-Host "Group already exists"
		}
		$i++
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
	$csvPath = "C:\users.csv"
	if (Test-Path $csvPath) {
		$csvUsers = Import-Csv -Path $csvPath
		foreach ($csvUser in $csvUsers) {
			
			Write-Host "Trying to add $csvUser."
			# Create the user in Active Directory
				New-ADUser `
					-Name "$($csvUser.FirstName) $($csvUser.LastName)" `
					-GivenName $csvUser.FirstName `
					-Surname $csvUser.LastName `
					-SamAccountName $csvUser.UserName `
					-Path $csvUser.OU`
					-AccountPassword (ConvertTo-SecureString $csvUser.Password -AsPlainText -Force) `
					-Enabled $true

				# Output success message
				Write-Host "Successfully created user: $($csvUser.UserName)"
			
		}
	}
	 else {
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

    # Create new groups for each folder in Share
    foreach ($group in @($groupR, $groupRWMX, $groupFC)) {
        if (-not (Get-ADGroup -Filter "Name -eq '$group'")) {
            New-ADGroup -Name $group -GroupScope DomainLocal -Path "OU=OU_DL,OU=MOOS,DC=moos,DC=local"
            Write-Host "Created group: $group"
        } else {
            Write-Host "Group already exists: $group"
        }
    }
    
    # Create the folder if it does not exist
    if (-not (Test-Path $folderPath)) {
        $tempFolder = New-Item -Path $folderPath -ItemType Directory
        Write-Host "Created folder: $folderPath"
    } else {
        Write-Host "Folder already exists: $folderPath"
    }

    # Get the ACL of the folder
    $acl = Get-Acl -Path $folderPath

    # Add read and execute permissions for $groupR
    $groupRSid = (Get-ADGroup -Filter "Name -eq '$groupR'").SID
    $permission = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($groupRSid, $permission, "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($accessRule)

    # Add read, write, execute, and modify permissions for $groupRWMX
    $groupRWMXSid = (Get-ADGroup -Filter "Name -eq '$groupRWMX'").SID
    $permissionsRWMX = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute -bor `
                       [System.Security.AccessControl.FileSystemRights]::Write -bor `
                       [System.Security.AccessControl.FileSystemRights]::Modify
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($groupRWMXSid, $permissionsRWMX, "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($accessRule)

    # Add full control permissions for $groupFC
    $groupFCSid = (Get-ADGroup -Filter "Name -eq '$groupFC'").SID
    $permission = [System.Security.AccessControl.FileSystemRights]::FullControl
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($groupFCSid, $permission, "ContainerInherit, ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($accessRule)

    # Set the updated ACL on the folder
    Set-Acl -Path $folderPath -AclObject $acl
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
