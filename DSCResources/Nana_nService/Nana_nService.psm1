function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[ValidateSet('Running','Stopped')]
		[System.String]
		$State
	)

  $service = Get-ServiceResource -Name $Name
  $ServiceWmiObject = Get-WmiService -Name $Name
	
	$returnValue = @{
		StartupType  = [System.String]$ServiceWmiObject.StartMode
		Name         = [System.String]$Name 
		DisplayName  = [System.String]$service.DisplayName
		State        = [System.String]$service.Status
	}

	$returnValue	
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[ValidateSet('Automatic','Manual','Disabled')]
		[System.String]
		$StartupType,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[ValidateSet('Running','Stopped')]
		[System.String]
		$State
	)

  Test-StartupType -Name $Name -StartupType $StartupType -State $State 

  $service = Get-ServiceResource -Name $Name

  if ($PSBoundParameters.ContainsKey('StartupType'))
  {
      Write-Verbose "Setting startup type of service $Name to $StartupType"
      Set-Service -Name $Name -StartupType $StartupType
  }

  if ($State -eq 'Running')
  {
      Write-Verbose "Starting service $Name"
      Start-Service $Name
  }
  else
  {
      Write-Verbose "Stopping service $Name"
      Stop-Service $Name -Force
  }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[ValidateSet('Automatic','Manual','Disabled')]
		[System.String]
		$StartupType,

		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[ValidateSet('Running','Stopped')]
		[System.String]
		$State
	)

  Test-StartupType -Name $Name -StartupType $StartupType -State $State 

  $service = Get-ServiceResource -Name $Name

  if ($service.Status -ne $State)
  {
      Write-Verbose "Service $Name is $($Service.Status). Desired state is $State"
      return $false
  }

  $ServiceWmiObject = Get-WmiService -Name $Name

  if ($PSBoundParameters.ContainsKey('StartupType'))
  {
      if (-not ($StartupType -eq 'Automatic' -and $ServiceWmiObject.StartMode -eq 'Auto') -and 
          -not ($StartupType -eq 'Disabled'  -and $ServiceWmiObject.StartMode -eq 'Disabled') -and
          -not ($StartupType -eq 'Manual'    -and $ServiceWmiObject.StartMode -eq 'Manual'))      
      {
          Write-Verbose "Service $Name is $($ServiceWmiObject.StartMode). Desired startup type is $StartupType"
          return $false
      }
  }

  return $true
}

<#
.Synopsis
Tests if startup type specified is valid, given the specified state
#>
function Test-StartupType
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        [System.String]
        $StartupType,

        [System.String]
        [ValidateSet('Running', 'Stopped')]
        $State='Running'
    )

    if($StartupType -eq $null) {return}

    if($State -eq 'Stopped')
    {
        if($StartupType -eq 'Automatic')
        {
            # State = Stopped conflicts with Automatic or Delayed
            throw "Cannot stop service $Name and set it to start automatically"
        }
    }
    else
    {
        if($StartupType -eq 'Disabled')
        {
            # State = Running conflicts with Disabled
            throw "Cannot start service $Name and disable it"
        }
    }
}

<#
.Synopsis
Gets a service corresponding to a name, throwing an error if not found
#>
function Get-ServiceResource
{
    param
    (
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    $svc=Get-Service $name -ErrorAction Ignore

    if($svc -eq $null)
    {
        throw "Service with name $Name not found"
    }

    return $svc
}

<#
.Synopsis
Gets a Win32_Service object corresponding to the name
#>
function Get-WmiService
{
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        $Name
    )

    try
    {
        return new-object management.managementobject "Win32_Service.Name='$Name'"
    }
    catch
    {
        Write-Verbose "Error retrieving win32_service information for $Name"
        throw
    }
}

Export-ModuleMember -Function *-TargetResource

