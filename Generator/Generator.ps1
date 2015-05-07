# Set this to the path where you want the module to 
# be generated. This has been set to a temporary
# location to prevent overriding the existing code
# during the demo
#$Script:PathToModule = 'D:\Nana\Official\git'
$Script:PathToModule = "$($env:TEMP)\Modules"

$Properties = @{}
$Properties += @{
    'Name' = (
            New-xDscResourceProperty -Name       'Name' `
                                     -Type        String `
                                     -Attribute   Key `
                                     -Description 'Name of the service');

    'DisplayName' = (
            New-xDscResourceProperty -Name        'DisplayName' `
                                     -Type        String `
                                     -Attribute   Read `
                                     -Description 'Display name for the service, if not specified, Name is used');

    'State' = (          
            New-xDscResourceProperty -Name        'State' `
                                     -Type        String  `
                                     -Attribute   Required `
                                     -Description 'State to set the service to' `
                                     -ValidateSet 'Running', 'Stopped');

    'StartupType' = (          
            New-xDscResourceProperty -Name        'StartupType' `
                                     -Type        String `
                                     -Attribute   Write `
                                     -Description 'StartupType to set for the service' `
                                     -ValidateSet 'Automatic', 'Manual', 'Disabled')
}

New-xDscResource -Name 'Nana_nService' `
                 -Property $Properties.Values `
                 -Path $Script:PathToModule `
                 -ModuleName nPSDesiredStateConfiguration `
                 -ClassVersion 0.1.0.0 `
                 -FriendlyName nService `
                 -Verbose